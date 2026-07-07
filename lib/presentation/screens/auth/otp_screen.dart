import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

/// 6-digit OTP verification. Receives the identifier via route arguments.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.identifier});

  final String identifier;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _length = 6;
  final List<TextEditingController> _digits =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());

  String get _code => _digits.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _digits) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.length < _length) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(widget.identifier, _code);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código verificado com sucesso.')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Código inválido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verificação')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Introduza o código de $_length dígitos enviado para ${widget.identifier}.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_length, (i) {
                  return SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _digits[i],
                      focusNode: _nodes[i],
                      autofocus: i == 0,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < _length - 1) {
                          _nodes[i + 1].requestFocus();
                        } else if (v.isEmpty && i > 0) {
                          _nodes[i - 1].requestFocus();
                        }
                        if (_code.length == _length) _verify();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: auth.isBusy ? null : _verify,
                child: auth.isBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Verificar'),
              ),
              TextButton(
                onPressed: auth.isBusy
                    ? null
                    : () => auth.forgotPassword(widget.identifier),
                child: const Text('Reenviar código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
