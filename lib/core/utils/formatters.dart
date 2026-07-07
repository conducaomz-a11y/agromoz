import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _metical = NumberFormat.currency(
    locale: 'pt_MZ',
    symbol: 'MT',
    decimalDigits: 0,
  );

  /// 12500 → "12.500 MT"
  static String price(num value) =>
      '${NumberFormat.decimalPattern('pt').format(value)} MT';

  static String currency(num value) => _metical.format(value);

  /// Relative time in Portuguese: "agora", "há 5 min", "há 2 h", "há 3 dias".
  static String timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String chatTime(DateTime date) => DateFormat('HH:mm').format(date);
}
