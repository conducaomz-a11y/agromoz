import 'user_model.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.description,
    this.images = const [],
    this.categoryId,
    this.categoryName,
    this.province,
    this.district,
    this.condition,
    this.unit,
    this.quantityAvailable,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isFavorite = false,
    this.seller,
    this.createdAt,
    this.viewCount = 0,
    this.cycle,
  });

  final String id;
  final String title;
  final double price;
  final String? description;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;
  final String? province;
  final String? district;
  final String? condition;

  /// e.g. "kg", "saco 50kg", "unidade", "litro"
  final String? unit;
  final double? quantityAvailable;
  final bool isAvailable;
  final bool isFeatured;
  final bool isFavorite;
  final UserModel? seller;
  final DateTime? createdAt;
  final int viewCount;
  final ProductCycle? cycle;

  String? get coverImage => images.isNotEmpty ? images.first : null;

  String get locationLabel =>
      [district, province].where((e) => e != null && e.isNotEmpty).join(', ');

  ProductModel copyWith({bool? isFavorite}) => ProductModel(
        id: id,
        title: title,
        price: price,
        description: description,
        images: images,
        categoryId: categoryId,
        categoryName: categoryName,
        province: province,
        district: district,
        condition: condition,
        unit: unit,
        quantityAvailable: quantityAvailable,
        isAvailable: isAvailable,
        isFeatured: isFeatured,
        isFavorite: isFavorite ?? this.isFavorite,
        seller: seller,
        createdAt: createdAt,
        viewCount: viewCount,
        cycle: cycle,
      );

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String?,
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        categoryId: json['category_id']?.toString(),
        categoryName: json['category_name'] as String?,
        province: json['province'] as String?,
        district: json['district'] as String?,
        condition: json['condition'] as String?,
        unit: json['unit'] as String?,
        quantityAvailable: (json['quantity_available'] as num?)?.toDouble(),
        isAvailable: json['is_available'] as bool? ?? true,
        isFeatured: json['is_featured'] as bool? ?? false,
        isFavorite: json['is_favorite'] as bool? ?? false,
        seller: json['seller'] is Map<String, dynamic>
            ? UserModel.fromJson(json['seller'] as Map<String, dynamic>)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
        cycle: json['cycle'] is Map<String, dynamic>
            ? ProductCycle.fromJson(json['cycle'] as Map<String, dynamic>)
            : null,
      );
}


/// Ciclo de vida do produto (colheita/reposição). Vem do campo "cycle" da API;
/// é null quando o produto não tem ciclo.
class ProductCycle {
  const ProductCycle({
    required this.type,
    required this.state,
    this.availableFrom,
    this.daysRemaining,
    required this.label,
    this.availability,
    this.canNotify = false,
  });

  /// "colheita" ou "reposicao".
  final String type;

  /// "crescendo", "pronto" ou "esgotado".
  final String state;

  /// Data prevista de disponibilidade (YYYY-MM-DD), ou null.
  final DateTime? availableFrom;

  /// Dias que faltam (pode ser 0/negativo), ou null.
  final int? daysRemaining;

  /// Texto pronto a mostrar, ex.: "Colheita prevista em 23 dias".
  final String label;

  /// "PreOrder", "InStock" ou "OutOfStock".
  final String? availability;

  /// Se faz sentido mostrar o sino "avisar-me".
  final bool canNotify;

  bool get isGrowing => state == 'crescendo';
  bool get isReady => state == 'pronto';
  bool get isSoldOut => state == 'esgotado';
  bool get isHarvest => type == 'colheita';

  factory ProductCycle.fromJson(Map<String, dynamic> json) => ProductCycle(
        type: json['type'] as String? ?? 'colheita',
        state: json['state'] as String? ?? 'crescendo',
        availableFrom: json['available_from'] != null
            ? DateTime.tryParse(json['available_from'].toString())
            : null,
        daysRemaining: (json['days_remaining'] as num?)?.toInt(),
        label: json['label'] as String? ?? '',
        availability: json['availability'] as String?,
        canNotify: json['can_notify'] as bool? ?? false,
      );
}
