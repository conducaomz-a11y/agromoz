import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/article_model.dart';
import '../models/paginated_response.dart';

class ArticleRepository {
  ArticleRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<PaginatedResponse<ArticleModel>> fetchArticles({
    int page = 1,
    String? categoryId,
    String? query,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.articles,
      query: {
        'page': page,
        if (categoryId != null) 'category_id': categoryId,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return PaginatedResponse.fromJson(data, ArticleModel.fromJson);
  }

  Future<ArticleModel> fetchArticle(String slugOrId) async {
    final data = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.articleDetail(slugOrId));
    return ArticleModel.fromJson(
      (data['data'] ?? data) as Map<String, dynamic>,
    );
  }

  Future<List<ArticleCategoryModel>> fetchCategories() async {
    final data = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.articleCategories);
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ArticleCategoryModel.fromJson)
        .toList();
  }
}
