import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _province;
  bool _obscure = true;
  bool _wantsBusiness = false;
  bool _acceptsTerms = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptsTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Tens de aceitar os Termos e Condições para criar conta.'),
      ));
      return;
    }
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final result = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      province: _province,
      wantsBusiness: _wantsBusiness,
    );
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            identifier: result.identifier,
            wantsBusiness: _wantsBusiness,
            debugCode: result.debugCode,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Falha ao criar a conta.')),
      );
    }
  }

  Future<void> _openSitePage(String path) async {
    final site = Uri.parse(ApiEndpoints.baseUrl).replace(path: '/$path');
    await launchUrl(site, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => Validators.required(v, 'O nome'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                    helperText:
                        'Vais receber um código de confirmação neste e-mail.',
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '84 123 4567',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _province,
                  decoration: const InputDecoration(
                    labelText: 'Província',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: AppConstants.provinces
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _province = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Senha (mínimo 6 caracteres)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) =>
                      v != _password.text ? 'As senhas não coincidem.' : null,
                ),
                const SizedBox(height: 20),
                // ── Quero criar página de negócio (igual ao site) ──
                CheckboxListTile(
                  value: _wantsBusiness,
                  onChanged: (v) =>
                      setState(() => _wantsBusiness = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                      '🌱 Quero criar uma página de negócio (fornecedor)'),
                  subtitle: const Text(
                    'Depois de confirmares o e-mail, criamos já a tua página.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                CheckboxListTile(
                  value: _acceptsTerms,
                  onChanged: (v) =>
                      setState(() => _acceptsTerms = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Li e aceito os '),
                      InkWell(
                        onTap: () => _openSitePage('termos-e-condicoes'),
                        child: Text('Termos e Condições',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline)),
                      ),
                      const Text(' e a '),
                      InkWell(
                        onTap: () => _openSitePage('politica-de-privacidade'),
                        child: Text('Política de Privacidade',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: auth.isBusy ? null : _submit,
                  child: auth.isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Criar Conta'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Já tens conta? Entrar aqui'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
