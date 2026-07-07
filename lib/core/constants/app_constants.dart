class AppConstants {
  AppConstants._();

  static const String appName = 'AgroMoz';
  static const int pageSize = 20;
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Províncias de Moçambique — used by marketplace filters.
  static const List<String> provinces = [
    'Maputo Cidade',
    'Maputo Província',
    'Gaza',
    'Inhambane',
    'Sofala',
    'Manica',
    'Tete',
    'Zambézia',
    'Nampula',
    'Cabo Delgado',
    'Niassa',
  ];

  static const List<String> productConditions = [
    'Novo',
    'Usado',
    'Recondicionado',
  ];
}
