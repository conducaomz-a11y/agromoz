import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';

/// Confirmação da conta com o código de 6 dígitos enviado por e-mail
/// (mesmo mecanismo do site). Ao confirmar, entra directamente na app —
/// e se marcou "quero criar página de negócio", vai para o wizard.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.identifier,
    this.wantsBusiness = false,
    this.debugCode,
  });

  final String identifier;
  final bool wantsBusiness;

  /// Só em modo de teste da API (DEBUG_OTP).
  final String? debugCode;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Facilita os testes enquanto DEBUG_OTP está ligado na API.
    if (widget.debugCode != null) _code.text = widget.debugCode!;
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduz o código de 6 dígitos.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(widget.identifier, _code.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.main, (_) => false);
      if (widget.wantsBusiness) {
        // Vai directo criar a página de negócio, como no site.
        Navigator.pushNamed(context, AppRouter.businessWizard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Código inválido.')),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendCode(widget.identifier);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Código reenviado para o teu e-mail.'
          : auth.error ?? 'Falha ao reenviar o código.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar e-mail')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_read_outlined,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'Enviámos um código de 6 dígitos para',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              Text(
                widget.identifier,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(letterSpacing: 12, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '······',
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 8),
              const Text(
                'O código expira em 30 minutos. Verifica também a pasta de spam.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: auth.isBusy ? null : _verify,
                child: auth.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Confirmar e entrar'),
              ),
              TextButton(
                onPressed: auth.isBusy ? null : _resend,
                child: const Text('Reenviar código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
