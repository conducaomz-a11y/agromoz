import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/business_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../providers/business_provider.dart';

/// Wizard de 5 passos para criar a Página de Negócio — igual ao site:
/// 1. Perfil · 2. Negócio · 3. Categorias · 4. Localização · 5. Imagens.
/// A página fica "pendente" até ser aprovada pela equipa AgroMoz.
class BusinessWizardScreen extends StatefulWidget {
  const BusinessWizardScreen({super.key});

  @override
  State<BusinessWizardScreen> createState() => _BusinessWizardScreenState();
}

class _BusinessWizardScreenState extends State<BusinessWizardScreen> {
  final _picker = ImagePicker();
  int _step = 0;

  // Passo 1
  List<BusinessTypeModel> _types = [];
  String? _type;

  // Passo 2
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _hours = TextEditingController();

  // Passo 3
  List<CategoryModel> _categories = [];
  final Set<String> _selectedCats = {};
  bool _loadingCats = false;

  // Passo 4
  String? _province;
  final _district = TextEditingController();
  final _address = TextEditingController();
  double? _lat;
  double? _lng;
  bool _locating = false;

  // Passo 5
  XFile? _logo;
  XFile? _cover;
  final List<XFile> _gallery = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      List<BusinessTypeModel> types = [];
      try {
        types = await context.read<BusinessProvider>().loadTypes();
      } catch (_) {/* usa o fallback abaixo */}
      if (types.isEmpty) {
        // Fallback local: nunca deixar o utilizador preso sem opções.
        types = const [
          BusinessTypeModel(key: 'agricultor', label: 'Agricultor'),
          BusinessTypeModel(key: 'horticultor', label: 'Horticultor'),
          BusinessTypeModel(key: 'avicultor', label: 'Avicultor'),
          BusinessTypeModel(key: 'cunicultor', label: 'Cunicultor'),
          BusinessTypeModel(
              key: 'vendedor_insumos', label: 'Fornecedor de Insumos'),
        ];
      }
      if (mounted) setState(() => _types = types);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name, _description, _phone, _whatsapp, _email,
      _website, _hours, _district, _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _loadCategories() async {
    if (_type == null) return;
    setState(() => _loadingCats = true);
    try {
      _categories =
          await context.read<BusinessProvider>().categoriesForType(_type!);
    } catch (_) {
      _categories = [];
    }
    if (mounted) setState(() => _loadingCats = false);
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('Permissão de localização negada.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _snack('Localização marcada ✅');
    } catch (_) {
      _snack('Não foi possível obter a localização. Activa o GPS.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pick(void Function(XFile) assign) async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (img != null) setState(() => assign(img));
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_type == null) {
          _snack('Escolhe um tipo de perfil.');
          return false;
        }
        return true;
      case 1:
        if (_name.text.trim().length < 3) {
          _snack('O nome tem de ter pelo menos 3 caracteres.');
          return false;
        }
        if (_description.text.trim().length < 20) {
          _snack('A descrição tem de ter pelo menos 20 caracteres — '
              'explica bem o teu negócio.');
          return false;
        }
        return true;
      case 2:
        if (_selectedCats.isEmpty) {
          _snack('Escolhe pelo menos uma categoria.');
          return false;
        }
        return true;
      case 3:
        if (_lat == null || _lng == null) {
          _snack('Marca a localização com o botão de GPS.');
          return false;
        }
        return true;
      case 4:
        if (_logo == null) {
          _snack('Envia uma imagem/logo do teu negócio.');
          return false;
        }
        return true;
    }
    return true;
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step == 2 - 1) await _loadCategories(); // ao entrar no passo 3
    if (_step < 4) {
      setState(() => _step++);
    } else {
      await _submit();
    }
  }

  Future<void> _submit() async {
    final provider = context.read<BusinessProvider>();
    final ok = await provider.createBusiness(BusinessInput(
      type: _type!,
      name: _name.text.trim(),
      description: _description.text.trim(),
      categoryIds: _selectedCats.toList(),
      province: _province,
      district: _district.text.trim(),
      address: _address.text.trim(),
      latitude: _lat,
      longitude: _lng,
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      email: _email.text.trim(),
      website: _website.text.trim(),
      hours: _hours.text.trim(),
      logoPath: _logo?.path,
      coverPath: _cover?.path,
      galleryPaths: _gallery.map((g) => g.path).toList(),
    ));
    if (!mounted) return;
    if (ok) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.hourglass_top_rounded, size: 40),
          title: const Text('Página criada! 🎉'),
          content: const Text(
            'A tua página está em revisão pela equipa AgroMoz. '
            'Assim que for aprovada, fica visível ao público — '
            'mas já podes começar a adicionar produtos.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } else {
      _snack(provider.error ?? 'Ocorreu um erro ao guardar. Tenta novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<BusinessProvider>().isBusy;
    final steps = ['Perfil', 'Negócio', 'Categorias', 'Localização', 'Imagens'];

    return Scaffold(
      appBar: AppBar(title: const Text('Criar Página de Negócio')),
      body: SafeArea(
        child: Column(
          children: [
            // ── Indicador de passos ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: i <= _step
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            child: Text('${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: i <= _step
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                )),
                          ),
                          const SizedBox(height: 4),
                          Text(steps[i],
                              style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildStep(),
              ),
            ),
            // ── Botões ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton.icon(
                      onPressed:
                          busy ? null : () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Voltar'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: busy ? null : _next,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(_step == 4
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded),
                    label:
                        Text(_step == 4 ? 'Publicar Página' : 'Continuar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _stepType();
      case 1:
        return _stepDetails();
      case 2:
        return _stepCategories();
      case 3:
        return _stepLocation();
      default:
        return _stepImages();
    }
  }

  // ── Passo 1: tipo de perfil ─────────────────────────────
  Widget _stepType() {
    const icons = {
      'agricultor': Icons.agriculture_rounded,
      'horticultor': Icons.eco_rounded,
      'avicultor': Icons.egg_rounded,
      'cunicultor': Icons.cruelty_free_rounded,
      'vendedor_insumos': Icons.storefront_rounded,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Qual é o teu perfil profissional?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        if (_types.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final t in _types)
                InkWell(
                  onTap: () => setState(() {
                    _type = t.key;
                    _selectedCats.clear();
                  }),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        width: 2,
                        color: _type == t.key
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                      color: _type == t.key
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: .35)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[t.key] ?? Icons.badge_rounded,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(t.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // ── Passo 2: dados do negócio ───────────────────────────
  Widget _stepDetails() {
    return Column(
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Nome do Negócio *',
            hintText: 'Ex: Machamba Boa Esperança',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _description,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Descrição Detalhada *',
            helperText:
                'Mínimo 20 caracteres. Quanto mais detalhes, melhor apareces nas pesquisas.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
              labelText: 'Telefone', hintText: '84xxxxxxx'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _whatsapp,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'WhatsApp',
            hintText: '84xxxxxxx',
            helperText: 'Os compradores vão falar contigo por aqui.',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration:
              const InputDecoration(labelText: 'E-mail de Contacto'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _website,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
              labelText: 'Website (opcional)', hintText: 'https://'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _hours,
          decoration: const InputDecoration(
            labelText: 'Horário de Funcionamento',
            hintText: 'Ex: Seg-Sáb, 07h-17h',
          ),
        ),
      ],
    );
  }

  // ── Passo 3: categorias filtradas pelo tipo ─────────────
  Widget _stepCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categorias de Produtos/Serviços',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Escolhe todas as que se aplicam ao teu negócio.',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 16),
        if (_loadingCats)
          const Center(child: CircularProgressIndicator())
        else if (_categories.isEmpty)
          const Text('Sem categorias disponíveis para este perfil.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _categories)
                FilterChip(
                  label: Text(c.name),
                  selected: _selectedCats.contains(c.id),
                  onSelected: (sel) => setState(() {
                    sel
                        ? _selectedCats.add(c.id)
                        : _selectedCats.remove(c.id);
                  }),
                ),
            ],
          ),
      ],
    );
  }

  // ── Passo 4: localização com GPS ────────────────────────
  Widget _stepLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Localização do Negócio',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Icon(
                  _lat != null
                      ? Icons.check_circle_rounded
                      : Icons.gps_fixed_rounded,
                  size: 40,
                  color: _lat != null
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  _lat != null
                      ? 'Localização marcada: '
                          '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                      : 'Marca o local exacto do teu negócio com o GPS do telefone.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(_lat != null
                      ? 'Marcar novamente'
                      : 'Usar a minha localização actual'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _province,
          decoration: const InputDecoration(labelText: 'Província'),
          items: AppConstants.provinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _province = v),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _district,
          decoration: const InputDecoration(labelText: 'Distrito'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _address,
          decoration:
              const InputDecoration(labelText: 'Endereço/Referência'),
        ),
      ],
    );
  }

  // ── Passo 5: imagens ────────────────────────────────────
  Widget _stepImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Imagens',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
            'O logo/foto principal é obrigatório. A capa e a galeria são opcionais.',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _UploadBox(
                label: 'Logo / Foto Principal *',
                file: _logo,
                onTap: () => _pick((f) => _logo = f),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UploadBox(
                label: 'Imagem de Capa',
                file: _cover,
                onTap: () => _pick((f) => _cover = f),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Galeria (várias imagens)',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in _gallery)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(g.path),
                        width: 76, height: 76, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => setState(() => _gallery.remove(g)),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child:
                            Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            InkWell(
              onTap: () => _pick((f) => _gallery.add(f)),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.file,
    required this.onTap,
  });

  final String label;
  final XFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: file != null
                ? Image.file(File(file!.path), fit: BoxFit.cover)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 30),
                      SizedBox(height: 4),
                      Text('Toca para enviar',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
