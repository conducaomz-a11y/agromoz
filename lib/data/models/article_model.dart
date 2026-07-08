/// Artigo educativo do site AgroMoz — a app abre o conteúdo completo
/// dentro da própria app (sem sair para o browser).
class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.publishedAt,
    this.content,
  });

  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;
  final DateTime? publishedAt;

  /// HTML completo do artigo — só vem no detalhe.
  final String? content;

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        excerpt: json['excerpt'] as String?,
        imageUrl: json['image_url'] as String?,
        categoryId: json['category_id']?.toString(),
        categoryName: json['category_name'] as String?,
        publishedAt: json['published_at'] != null
            ? DateTime.tryParse(json['published_at'].toString())
            : null,
        content: json['content'] as String?,
      );
}

/// Categoria de artigos (com contagem).
class ArticleCategoryModel {
  const ArticleCategoryModel({
    required this.id,
    required this.name,
    this.articleCount = 0,
  });

  final String id;
  final String name;
  final int articleCount;

  factory ArticleCategoryModel.fromJson(Map<String, dynamic> json) =>
      ArticleCategoryModel(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        articleCount: (json['article_count'] as num?)?.toInt() ?? 0,
      );
}
