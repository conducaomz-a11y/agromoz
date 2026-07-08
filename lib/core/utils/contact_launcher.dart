import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre uma conversa de WhatsApp com o número indicado.
///
/// Normaliza números moçambicanos: "84 123 4567" → "258841234567".
/// Se o WhatsApp não estiver instalado, cai para o wa.me no browser.
class ContactLauncher {
  ContactLauncher._();

  static String normalizeMz(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    // Número local de 9 dígitos (8x xxx xxxx) → prefixo de Moçambique.
    if (digits.length == 9 && digits.startsWith('8')) digits = '258$digits';
    return digits;
  }

  static Future<void> openWhatsApp(
    BuildContext context, {
    required String phone,
    String? message,
  }) async {
    final number = normalizeMz(phone);
    if (number.isEmpty) {
      _snack(context, 'Este vendedor não tem número de contacto.');
      return;
    }
    final text = message == null ? '' : '?text=${Uri.encodeComponent(message)}';
    final appUri = Uri.parse('whatsapp://send?phone=$number'
        '${message == null ? '' : '&text=${Uri.encodeComponent(message)}'}');
    final webUri = Uri.parse('https://wa.me/$number$text');

    // 1º tenta a app do WhatsApp, depois o wa.me.
    if (await canLaunchUrl(appUri) && await launchUrl(appUri)) return;
    if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) return;
    if (context.mounted) {
      _snack(context, 'Não foi possível abrir o WhatsApp.');
    }
  }

  static Future<void> call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri) && context.mounted) {
      _snack(context, 'Não foi possível iniciar a chamada.');
    }
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
