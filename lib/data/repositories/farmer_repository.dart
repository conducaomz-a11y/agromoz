import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/paginated_response.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';

class FarmerRepository {
  FarmerRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  /// Lista pública de fornecedores/empresas (com filtro por tipo e pesquisa).
  Future<PaginatedResponse<UserModel>> fetchFarmers({
    int page = 1,
    String? type,
    String? query,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.farmers,
      query: {
        'page': page,
        if (type != null) 'type': type,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return PaginatedResponse.fromJson(data, UserModel.fromJson);
  }

  Future<UserModel> fetchFarmer(String id) async {
    final data = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.farmerProfile(id));
    return UserModel.fromJson((data['data'] ?? data) as Map<String, dynamic>);
  }

  Future<List<ProductModel>> fetchFarmerProducts(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      query: {'seller_id': id},
    );
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  /// Envia (ou actualiza) a avaliação do utilizador para esta empresa.
  Future<void> postReview({
    required String farmerId,
    required int rating,
    String? comment,
  }) =>
      _client.post<void>(
        ApiEndpoints.farmerReviewCreate(farmerId),
        data: {'rating': rating, 'comment': comment},
      );

  Future<List<ReviewModel>> fetchReviews(String id) async {
    final data = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.farmerReviews(id));
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList();
  }
}
