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
import '../../widgets/app_network_image.dart';

/// Edição da Página de Negócio — o dono pode mudar logo, capa,
/// descrição, contactos, categorias e localização a qualquer momento.
class BusinessEditScreen extends StatefulWidget {
  const BusinessEditScreen({super.key});

  @override
  State<BusinessEditScreen> createState() => _BusinessEditScreenState();
}

class _BusinessEditScreenState extends State<BusinessEditScreen> {
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final BusinessModel _b;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _hours;
  late final TextEditingController _district;
  late final TextEditingController _address;
  String? _province;
  double? _lat;
  double? _lng;
  bool _locating = false;

  XFile? _newLogo;
  XFile? _newCover;
  final List<XFile> _newGallery = [];

  List<CategoryModel> _categories = [];
  final Set<String> _selectedCats = {};
  bool _loadingCats = true;

  @override
  void initState() {
    super.initState();
    _b = context.read<BusinessProvider>().business!;
    _name = TextEditingController(text: _b.name);
    _description = TextEditingController(text: _b.description ?? '');
    _phone = TextEditingController(text: _b.phone ?? '');
    _whatsapp = TextEditingController(text: _b.whatsapp ?? '');
    _email = TextEditingController(text: _b.email ?? '');
    _website = TextEditingController(text: _b.website ?? '');
    _hours = TextEditingController(text: _b.hours ?? '');
    _district = TextEditingController(text: _b.district ?? '');
    _address = TextEditingController(text: _b.address ?? '');
    _province =
        AppConstants.provinces.contains(_b.province) ? _b.province : null;
    _lat = _b.latitude;
    _lng = _b.longitude;
    _selectedCats.addAll(_b.categories.map((c) => c.id));
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _categories =
          await context.read<BusinessProvider>().categoriesForType(_b.type);
    } catch (_) {
      _categories = [];
    }
    if (mounted) setState(() => _loadingCats = false);
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

  Future<void> _pick(void Function(XFile) assign) async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (img != null) setState(() => assign(img));
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
      _snack('Localização actualizada ✅');
    } catch (_) {
      _snack('Não foi possível obter a localização. Activa o GPS.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCats.isEmpty) {
      _snack('Escolhe pelo menos uma categoria.');
      return;
    }
    FocusScope.of(context).unfocus();

    final provider = context.read<BusinessProvider>();
    final ok = await provider.updateBusiness(BusinessInput(
      type: _b.type,
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
      logoPath: _newLogo?.path,
      coverPath: _newCover?.path,
      galleryPaths: _newGallery.map((g) => g.path).toList(),
    ));
    if (!mounted) return;
    if (ok) {
      _snack('Página actualizada com sucesso ✅');
      Navigator.pop(context, true);
    } else {
      _snack(provider.error ?? 'Ocorreu um erro ao guardar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<BusinessProvider>().isBusy;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Página')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Imagens: capa + logo sobreposto ──
              SizedBox(
                height: 170,
                child: Stack(
                  children: [
                    // capa
                    InkWell(
                      onTap: () => _pick((f) => _newCover = f),
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: theme.dividerColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _newCover != null
                            ? Image.file(File(_newCover!.path),
                                fit: BoxFit.cover)
                            : (_b.coverUrl != null
                                ? AppNetworkImage(url: _b.coverUrl)
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.image_outlined, size: 28),
                                        Text('Toca para mudar a capa',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  )),
                      ),
                    ),
                    // logo
                    Positioned(
                      left: 16,
                      bottom: 0,
                      child: InkWell(
                        onTap: () => _pick((f) => _newLogo = f),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.colorScheme.surface, width: 3),
                            color: theme.colorScheme.surface,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _newLogo != null
                              ? Image.file(File(_newLogo!.path),
                                  fit: BoxFit.cover)
                              : (_b.logoUrl != null
                                  ? AppNetworkImage(url: _b.logoUrl)
                                  : const Icon(Icons.add_a_photo_outlined)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Tocar para mudar',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Nome do Negócio *'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Mínimo 3 caracteres.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Empresa *',
                  alignLabelWithHint: true,
                  helperText:
                      'Quanto mais detalhes, melhor apareces nas pesquisas.',
                ),
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Mínimo 20 caracteres.'
                    : null,
              ),
              const SizedBox(height: 20),
              Text('Categorias',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (_loadingCats)
                const Center(child: CircularProgressIndicator())
              else if (_categories.isEmpty)
                const Text('Sem categorias disponíveis.')
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
              const SizedBox(height: 20),
              Text('Contactos',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  helperText: 'Os compradores falam contigo por aqui.',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'E-mail de Contacto'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    labelText: 'Website', hintText: 'https://'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hours,
                decoration: const InputDecoration(
                    labelText: 'Horário', hintText: 'Ex: Seg-Sáb, 07h-17h'),
              ),
              const SizedBox(height: 20),
              Text('Localização',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _province,
                decoration: const InputDecoration(labelText: 'Província'),
                items: AppConstants.provinces
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _province = v),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _district,
                decoration: const InputDecoration(labelText: 'Distrito'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                    labelText: 'Endereço/Referência'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(_lat != null
                    ? 'Localização marcada '
                        '(${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}) — remarcar'
                    : 'Marcar localização com GPS'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: busy ? null : _save,
                icon: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Guardar Alterações'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
