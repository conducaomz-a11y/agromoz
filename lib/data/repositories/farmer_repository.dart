import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';

class FarmerRepository {
  FarmerRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

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

  Future<List<ReviewModel>> fetchReviews(String id) async {
    final data = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.farmerReviews(id));
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList();
  }
}
