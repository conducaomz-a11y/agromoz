import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class GlobalSearchResult {
  const GlobalSearchResult({
    this.products = const [],
    this.farmers = const [],
    this.companies = const [],
    this.categories = const [],
  });

  final List<ProductModel> products;
  final List<UserModel> farmers;
  final List<UserModel> companies;
  final List<CategoryModel> categories;

  bool get isEmpty =>
      products.isEmpty &&
      farmers.isEmpty &&
      companies.isEmpty &&
      categories.isEmpty;
}

class SearchRepository {
  SearchRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<List<String>> suggestions(String query) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.searchSuggestions,
      query: {'q': query},
    );
    return (data['data'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
  }

  Future<GlobalSearchResult> search(String query) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.search,
      query: {'q': query},
    );
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        (data[key] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();

    return GlobalSearchResult(
      products: parse('products', ProductModel.fromJson),
      farmers: parse('farmers', UserModel.fromJson),
      companies: parse('companies', UserModel.fromJson),
      categories: parse('categories', CategoryModel.fromJson),
    );
  }
}
