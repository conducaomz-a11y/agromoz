/// Artigo do blog do site AgroMoz (endpoint GET /articles).
///
/// Ao tocar num artigo, a app abre [url] no navegador — a leitura
/// acontece no próprio site, gerando visitas e receita de anúncios.
class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.url,
    this.excerpt,
    this.imageUrl,
    this.categoryName,
    this.publishedAt,
    this.views = 0,
  });

  final String id;
  final String title;
  final String url;
  final String? excerpt;
  final String? imageUrl;
  final String? categoryName;
  final DateTime? publishedAt;
  final int views;

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
        excerpt: json['excerpt'] as String?,
        imageUrl: json['image_url'] as String?,
        categoryName: json['category_name'] as String?,
        publishedAt: json['published_at'] != null
            ? DateTime.tryParse(json['published_at'].toString())
            : null,
        views: (json['views'] as num?)?.toInt() ?? 0,
      );
}
