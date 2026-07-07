class Validators {
  Validators._();

  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'O e-mail é obrigatório.';
    final re = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\.\-]+$');
    if (!re.hasMatch(value.trim())) return 'Introduza um e-mail válido.';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O número de telefone é obrigatório.';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return 'Introduza um número válido (ex.: 84 123 4567).';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'A palavra-passe é obrigatória.';
    if (value.length < 6) return 'Mínimo de 6 caracteres.';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value != original()) return 'As palavras-passe não coincidem.';
      return null;
    };
  }
}
