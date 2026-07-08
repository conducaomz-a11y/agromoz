import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/models/business_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../providers/business_provider.dart';
import '../../widgets/app_network_image.dart';

/// Criar/editar produto — igual ao produto-form do site:
/// preço vazio → "sob consulta"; unidade livre; disponibilidade; destaque.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  /// null → criar novo.
  final OwnProductModel? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final _name = TextEditingController(text: widget.product?.title);
  late final _description =
      TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(
      text: widget.product?.price?.toStringAsFixed(2) ?? '');
  late final _unit = TextEditingController(text: widget.product?.unit);

  String? _categoryId;
  String _availability = 'disponivel';
  bool _featured = false;
  XFile? _image;
  List<CategoryModel> _categories = [];

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _categoryId = p.categoryId;
      _availability = p.availability;
      _featured = p.isFeatured;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    final provider = context.read<BusinessProvider>();
    final type = provider.business?.type;
    if (type == null) return;
    try {
      final cats = await provider.categoriesForType(type);
      if (mounted) {
        setState(() {
          _categories = cats;
          // evita valor inválido no dropdown
          if (_categoryId != null &&
              !cats.any((c) => c.id == _categoryId)) {
            _categoryId = null;
          }
        });
      }
    } catch (_) {/* dropdown fica vazio — categoria é opcional */}
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _unit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (img != null) setState(() => _image = img);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final priceText = _price.text.trim().replaceAll(',', '.');
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
        imagePath: _image?.path,
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

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<BusinessProvider>().isBusy;
    final existingImage = widget.product?.images.isNotEmpty == true
        ? widget.product!.images.first
        : null;

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
                    const DropdownMenuItem(
                        value: null, child: Text('— Seleccionar —')),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                  decoration:
                      const InputDecoration(labelText: 'Disponibilidade'),
                  items: const [
                    DropdownMenuItem(
                        value: 'disponivel', child: Text('✅ Disponível')),
                    DropdownMenuItem(
                        value: 'esgotando', child: Text('⚠️ A Esgotar')),
                    DropdownMenuItem(
                        value: 'indisponivel',
                        child: Text('❌ Indisponível')),
                  ],
                  onChanged: (v) =>
                      setState(() => _availability = v ?? 'disponivel'),
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
                      border:
                          Border.all(color: Theme.of(context).dividerColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _image != null
                        ? Image.file(File(_image!.path), fit: BoxFit.cover)
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
                  title:
                      const Text('Destacar este produto na minha página'),
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
