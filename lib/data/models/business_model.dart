/// Modelos do fluxo profissional — espelham as tabelas do site
/// (empresas, categorias_negocio, produtos).

class BusinessTypeModel {
  const BusinessTypeModel({required this.key, required this.label});
  final String key; // agricultor | horticultor | avicultor | cunicultor | vendedor_insumos
  final String label;

  factory BusinessTypeModel.fromJson(Map<String, dynamic> json) =>
      BusinessTypeModel(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class BusinessCategoryRef {
  const BusinessCategoryRef({required this.id, required this.name});
  final String id;
  final String name;

  factory BusinessCategoryRef.fromJson(Map<String, dynamic> json) =>
      BusinessCategoryRef(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
      );
}

/// A página de negócio (empresa) do utilizador.
class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.status,
    this.description,
    this.province,
    this.district,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.hours,
    this.logoUrl,
    this.coverUrl,
    this.views = 0,
    this.categories = const [],
  });

  final String id;
  final String name;
  final String type;
  final String typeLabel;

  /// pendente (em revisão) | ativo | ...
  final String status;
  final String? description;
  final String? province;
  final String? district;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String? hours;
  final String? logoUrl;
  final String? coverUrl;
  final int views;
  final List<BusinessCategoryRef> categories;

  bool get isPending => status == 'pendente';

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        typeLabel: json['type_label'] as String? ?? '',
        status: json['status'] as String? ?? 'pendente',
        description: json['description'] as String?,
        province: json['province'] as String?,
        district: json['district'] as String?,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        phone: json['phone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        hours: json['hours'] as String?,
        logoUrl: json['logo_url'] as String?,
        coverUrl: json['cover_url'] as String?,
        views: (json['views'] as num?)?.toInt() ?? 0,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BusinessCategoryRef.fromJson)
            .toList(),
      );
}

/// Estatísticas do dashboard profissional (iguais aos cartões do site).
class BusinessStatsModel {
  const BusinessStatsModel({
    required this.business,
    this.totalProducts = 0,
    this.available = 0,
    this.runningOut = 0,
    this.unavailable = 0,
    this.pageViews = 0,
  });

  final BusinessModel business;
  final int totalProducts;
  final int available;
  final int runningOut;
  final int unavailable;
  final int pageViews;

  factory BusinessStatsModel.fromJson(Map<String, dynamic> json) =>
      BusinessStatsModel(
        business:
            BusinessModel.fromJson(json['business'] as Map<String, dynamic>),
        totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
        available: (json['available'] as num?)?.toInt() ?? 0,
        runningOut: (json['running_out'] as num?)?.toInt() ?? 0,
        unavailable: (json['unavailable'] as num?)?.toInt() ?? 0,
        pageViews: (json['page_views'] as num?)?.toInt() ?? 0,
      );
}

/// Produto na óptica do DONO (inclui disponibilidade, destaque e estado).
class OwnProductModel {
  const OwnProductModel({
    required this.id,
    required this.title,
    this.price,
    this.description,
    this.images = const [],
    this.categoryId,
    this.categoryName,
    this.unit,
    this.availability = 'disponivel',
    this.isFeatured = false,
    this.status = 'ativo',
    this.views = 0,
  });

  final String id;
  final String title;

  /// null → "sob consulta" (igual ao site).
  final double? price;
  final String? description;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;
  final String? unit;

  /// disponivel | esgotando | indisponivel
  final String availability;
  final bool isFeatured;
  final String status;
  final int views;

  String get availabilityLabel {
    switch (availability) {
      case 'esgotando':
        return 'A Esgotar';
      case 'indisponivel':
        return 'Indisponível';
      default:
        return 'Disponível';
    }
  }

  factory OwnProductModel.fromJson(Map<String, dynamic> json) =>
      OwnProductModel(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble(),
        description: json['description'] as String?,
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        categoryId: json['category_id']?.toString(),
        categoryName: json['category_name'] as String?,
        unit: json['unit'] as String?,
        availability: json['availability'] as String? ?? 'disponivel',
        isFeatured: json['is_featured'] as bool? ?? false,
        status: json['status'] as String? ?? 'ativo',
        views: (json['views'] as num?)?.toInt() ?? 0,
      );
}
