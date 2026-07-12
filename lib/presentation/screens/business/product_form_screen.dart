import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/credits/credit_service.dart';
import '../../../core/utils/image_picker_service.dart';
import '../../../data/models/business_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../providers/business_provider.dart';
import '../../widgets/app_network_image.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final OwnProductModel? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.product?.title);
  late final _description = TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(
      text: widget.product?.price?.toStringAsFixed(2) ?? '');
  late final _unit = TextEditingController(text: widget.product?.unit);

  String? _categoryId;
  String _availability = 'disponivel';
  bool _featured = false;
  String? _imagePath;
  List<CategoryModel> _categories = [];

  // ── Ciclo de vida ──
  bool _usarCiclo = false;
  String _tipoCiclo = 'colheita';
  String _estadoCiclo = 'crescendo';
  DateTime? _dataDisponivel;
  final _quantidade = TextEditingController();

  // ── IA / créditos ──
  bool _generatingDesc = false;
  int _credits = 0;
  final _bizRepo = BusinessRepository();

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _categoryId = p.categoryId;
      _availability = p.availability;
      _featured = p.isFeatured;
      if (p.tipoCiclo != 'nenhum') {
        _usarCiclo = true;
        _tipoCiclo = p.tipoCiclo;
        _estadoCiclo = p.estadoCiclo ?? 'crescendo';
        if (p.dataDisponivel != null) {
          _dataDisponivel = DateTime.tryParse(p.dataDisponivel!);
        }
      }
      if (p.quantidade != null) _quantidade.text = p.quantidade.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCategories();
      _resolveTipoCiclo();
      await _refreshCredits();
      AdService.instance.preloadRewarded();
    });
  }

  Future<void> _refreshCredits() async {
    final bal = await CreditService.instance.fetchBalance();
    if (mounted) setState(() => _credits = bal);
  }

  void _resolveTipoCiclo() {
    if (_editing && widget.product!.tipoCiclo != 'nenhum') return;
    final type = context.read<BusinessProvider>().business?.type;
    const colheita = {'agricultor', 'horticultor'};
    setState(() {
      _tipoCiclo = colheita.contains(type) ? 'colheita' : 'reposicao';
    });
  }

  bool get _ehColheita => _tipoCiclo == 'colheita';

  Future<void> _loadCategories() async {
    final provider = context.read<BusinessProvider>();
    final type = provider.business?.type;
    if (type == null) return;
    try {
      final cats = await provider.categoriesForType(type);
      if (mounted) {
        setState(() {
          _categories = cats;
          if (_categoryId != null && !cats.any((c) => c.id == _categoryId)) {
            _categoryId = null;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _unit, _quantidade]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await ImagePickerService.instance
        .pickAndCompress(context, maxDimension: 1600, quality: 85);
    if (path != null && mounted) setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usarCiclo && _estadoCiclo == 'crescendo' && _dataDisponivel == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_ehColheita
            ? 'Indica a data prevista de colheita.'
            : 'Indica a data prevista de reposição.'),
      ));
      return;
    }
    FocusScope.of(context).unfocus();

    final priceText = _price.text.trim().replaceAll(',', '.');
    final qtdText = _quantidade.text.trim();
    final provider = context.read<BusinessProvider>();
    final ok = await provider.saveProduct(
      id: widget.product?.id,
      input: ProductInput(
        name: _name.text.trim(),
        categoryId: _categoryId,
        description: _description.text.trim(),
        price: priceText.isEmpty ? null : double.tryParse(priceText),
        unit: _unit.text.trim(),
        availability: _availability,
        featured: _featured,
        imagePath: _imagePath,
        tipoCiclo: _usarCiclo ? _tipoCiclo : 'nenhum',
        estadoCiclo: _usarCiclo ? _estadoCiclo : null,
        dataDisponivel: _usarCiclo && _dataDisponivel != null
            ? _fmtDate(_dataDisponivel!)
            : null,
        quantidade: qtdText.isEmpty ? null : int.tryParse(qtdText),
      ),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto guardado com sucesso.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Falha ao guardar.')),
      );
    }
  }

  /// Fluxo principal: tem crédito → gera; sem crédito → vê anúncio primeiro.
  Future<void> _gerarDescricaoIA() async {
    final nome = _name.text.trim();
    if (nome.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreve primeiro o nome do produto.')),
      );
      return;
    }

    if (CreditService.instance.canGenerate) {
      // Tem crédito — gera diretamente
      await _gerarComCredito(nome);
    } else {
      // Sem crédito — mostra diálogo para ver anúncio
      await _pedirAnuncioParaCredito(nome);
    }
  }

  /// Gera a descrição debitando 1 crédito.
  Future<void> _gerarComCredito(String nome) async {
    String? categoria;
    for (final c in _categories) {
      if (c.id == _categoryId) {
        categoria = c.name;
        break;
      }
    }
    final provincia = context.read<BusinessProvider>().business?.province;

    final spent = await CreditService.instance.spend();
    if (!spent || !mounted) return;

    await _refreshCredits();
    setState(() => _generatingDesc = true);

    try {
      final texto = await _bizRepo.generateDescription(
        name: nome,
        category: categoria,
        province: provincia,
      );
      if (!mounted) return;
      if (texto.isNotEmpty) {
        setState(() => _description.text = texto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Descrição gerada! Podes editar.')),
        );
      } else {
        // Reembolsa o crédito se a API não devolveu nada
        await CreditService.instance.refund();
        await _refreshCredits();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível gerar. Crédito devolvido.')),
        );
      }
    } catch (e) {
      // Reembolsa o crédito em caso de erro
      await CreditService.instance.refund();
      await _refreshCredits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar: $e. Crédito devolvido.')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingDesc = false);
    }
  }

  /// Mostra diálogo a explicar que precisa de ver anúncio para ganhar crédito.
  Future<void> _pedirAnuncioParaCredito(String nome) async {
    final ver = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sem créditos de IA'),
        content: const Text(
          'Vê um anúncio curto para ganhar 1 crédito e gerar a descrição automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('Ver anúncio (+1 crédito)'),
          ),
        ],
      ),
    );
    if (ver != true || !mounted) return;

    // Verifica se o anúncio está pronto
    if (!AdService.instance.isRewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anúncio ainda a carregar. Tenta daqui a pouco.'),
          duration: Duration(seconds: 3),
        ),
      );
      AdService.instance.preloadRewarded();
      return;
    }

    bool ganhouCredito = false;
    final mostrou = await AdService.instance.showRewarded(
      onReward: () async {
        ganhouCredito = true;
        await CreditService.instance.addCreditsFromAd();
      },
    );

    if (!mounted) return;

    if (!mostrou) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível mostrar o anúncio. Tenta de novo.')),
      );
      return;
    }

    if (!ganhouCredito) {
      // Utilizador fechou o anúncio antes do fim
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vê o anúncio até ao fim para ganhar o crédito.')),
      );
      return;
    }

    await _refreshCredits();

    // Crédito ganho — gera imediatamente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 +1 crédito ganho! A gerar descrição...'),
        duration: Duration(seconds: 2),
      ),
    );
    await _gerarComCredito(nome);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataDisponivel ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dataDisponivel = picked);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<BusinessProvider>().isBusy;
    final existingImage = widget.product?.images.isNotEmpty == true
        ? widget.product!.images.first
        : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar Produto' : 'Novo Produto/Serviço'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Produto/Serviço *',
                    hintText: 'Ex: Saco de Milho 50kg',
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'O nome do produto é obrigatório.'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Seleccionar —')),
                    for (final c in _categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Detalhes sobre o produto/serviço...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Botão Gerar IA + saldo de créditos ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generatingDesc ? null : _gerarDescricaoIA,
                        icon: _generatingDesc
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_generatingDesc
                            ? 'A gerar...'
                            : 'Gerar descrição com IA'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Badge de créditos
                    GestureDetector(
                      onTap: _credits == 0 ? () => _pedirAnuncioParaCredito('') : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _credits > 0
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _credits > 0
                                  ? Icons.bolt_rounded
                                  : Icons.bolt_outlined,
                              size: 16,
                              color: _credits > 0
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_credits crédito${_credits == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _credits > 0
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Hint quando sem créditos
                if (_credits == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Sem créditos. Toca em "Gerar" para ver um anúncio e ganhar 1 crédito.',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Preço (MT)',
                          helperText: 'Vazio = "sob consulta"',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Unidade',
                          hintText: 'por saco 50kg',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _availability,
                  decoration: const InputDecoration(labelText: 'Disponibilidade'),
                  items: const [
                    DropdownMenuItem(value: 'disponivel', child: Text('✅ Disponível')),
                    DropdownMenuItem(value: 'esgotando', child: Text('⚠️ A Esgotar')),
                    DropdownMenuItem(value: 'indisponivel', child: Text('❌ Indisponível')),
                  ],
                  onChanged: (v) => setState(() => _availability = v ?? 'disponivel'),
                ),
                const SizedBox(height: 8),

                // ── Ciclo de vida ──
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          value: _usarCiclo,
                          onChanged: (v) => setState(() => _usarCiclo = v),
                          title: Text(_ehColheita
                              ? 'Este produto tem ciclo de colheita'
                              : 'Este produto tem reposição de stock'),
                          subtitle: Text(_ehColheita
                              ? 'Mostra os dias até à colheita e permite pré-encomenda.'
                              : 'Mostra quando o stock será reposto.'),
                        ),
                        if (_usarCiclo) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _estadoCiclo,
                                  decoration:
                                      const InputDecoration(labelText: 'Estado'),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'crescendo',
                                        child: Text(_ehColheita
                                            ? '🌱 A crescer'
                                            : '⏳ A repor')),
                                    const DropdownMenuItem(
                                        value: 'pronto',
                                        child: Text('✅ Pronto / Disponível')),
                                    const DropdownMenuItem(
                                        value: 'esgotado',
                                        child: Text('❌ Esgotado')),
                                  ],
                                  onChanged: (v) => setState(
                                      () => _estadoCiclo = v ?? 'crescendo'),
                                ),
                                if (_estadoCiclo == 'crescendo') ...[
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: _ehColheita
                                            ? 'Data prevista de colheita'
                                            : 'Data prevista de reposição',
                                        suffixIcon: const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 18),
                                      ),
                                      child: Text(
                                        _dataDisponivel != null
                                            ? _fmtDate(_dataDisponivel!)
                                            : 'Toca para escolher',
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _quantidade,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantidade em stock',
                                    helperText:
                                        'Opcional — deixa vazio se não controlas.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Imagem ──
                const Text('Imagem',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath != null
                        ? Image.file(
                            ImagePickerService.fileFor(_imagePath!),
                            fit: BoxFit.cover)
                        : existingImage != null
                            ? AppNetworkImage(url: existingImage)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 36),
                                  SizedBox(height: 6),
                                  Text('Toca para enviar'),
                                ],
                              ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _featured,
                  onChanged: (v) => setState(() => _featured = v),
                  title: const Text('Destacar este produto na minha página'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: busy ? null : _save,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
