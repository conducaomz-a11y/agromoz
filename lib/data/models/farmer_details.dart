import 'user_model.dart';

/// Imagem da galeria da empresa (tabela empresa_imagens do site).
class GalleryImage {
  const GalleryImage({required this.url, this.caption});

  final String url;
  final String? caption;

  factory GalleryImage.fromJson(Map<String, dynamic> json) => GalleryImage(
        url: json['url'] as String? ?? '',
        caption: json['caption'] as String?,
      );
}

/// Perfil completo do Fornecedor (empresa do site) — tudo o que o
/// site mostra: capa, endereço, WhatsApp, website, horário e galeria.
class FarmerDetails {
  const FarmerDetails({
    required this.user,
    this.coverUrl,
    this.address,
    this.whatsapp,
    this.website,
    this.schedule,
    this.latitude,
    this.longitude,
    this.views = 0,
    this.gallery = const [],
  });

  final UserModel user;
  final String? coverUrl;
  final String? address;
  final String? whatsapp;
  final String? website;
  final String? schedule;
  final double? latitude;
  final double? longitude;
  final int views;
  final List<GalleryImage> gallery;

  factory FarmerDetails.fromJson(Map<String, dynamic> json) => FarmerDetails(
        user: UserModel.fromJson(json),
        coverUrl: json['cover_url'] as String?,
        address: json['address'] as String?,
        whatsapp: json['whatsapp'] as String?,
        website: json['website'] as String?,
        schedule: json['schedule'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        views: (json['views'] as num?)?.toInt() ?? 0,
        gallery: (json['gallery'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(GalleryImage.fromJson)
            .toList(),
      );
}
