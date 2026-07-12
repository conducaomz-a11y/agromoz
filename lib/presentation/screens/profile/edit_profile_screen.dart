import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_picker_service.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _district;
  late final TextEditingController _bio;
  String? _province;
  String? _localAvatar;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _district = TextEditingController(text: user?.district ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
    _province = user?.province;
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _district, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    final path = await ImagePickerService.instance.pickAndCompress(context);
    if (path == null || !mounted) return;
    setState(() {
      _localAvatar = path;
      _uploadingAvatar = true;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.uploadAvatar(path);
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);
    if (!ok) {
      setState(() => _localAvatar = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Falha ao actualizar a foto.')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final current = auth.user!;
    final updated = UserModel(
      id: current.id,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      province: _province,
      district: _district.text.trim().isEmpty ? null : _district.text.trim(),
      bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      role: current.role,
      avatarUrl: current.avatarUrl,
    );
    final ok = await auth.updateProfile(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Perfil actualizado com sucesso.'
            : auth.error ?? 'Falha ao actualizar o perfil.'),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      _localAvatar != null
                          ? CircleAvatar(
                              radius: 48,
                              backgroundImage: FileImage(
                                  ImagePickerService.fileFor(_localAvatar!)),
                            )
                          : UserAvatar(
                              name: user?.name ?? '',
                              imageUrl: user?.avatarUrl,
                              radius: 48,
                            ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          iconSize: 18,
                          tooltip: 'Alterar foto',
                          onPressed: _uploadingAvatar ? null : _changeAvatar,
                          icon: _uploadingAvatar
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (v) => Validators.required(v, 'O nome'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  validator: Validators.phone,
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _district,
                  decoration: const InputDecoration(labelText: 'Distrito'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bio,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Biografia',
                    hintText:
                        'Fale sobre a sua machamba, produtos ou serviços…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: auth.isBusy ? null : _save,
                  child: auth.isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Guardar alterações'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
