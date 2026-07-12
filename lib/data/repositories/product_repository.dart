import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/cache_service.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/paginated_response.dart';
import '../models/product_model.dart';

/// Filter object passed from the Marketplace UI down to the API query string.
class ProductFilters {
  const ProductFilters({
    this.query,
    this.categoryId,
    this.province,
    this.district,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.sort,
  });

  final String? query;
  final String? categoryId;
  final String? province;
  final String? district;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final String? sort; // recent | price_asc | price_desc

  bool get isEmpty =>
      categoryId == null &&
      province == null &&
      district == null &&
      minPrice == null &&
      maxPrice == null &&
      condition == null;

  int get activeCount => [
        categoryId,
        province,
        district,
        minPrice,
        maxPrice,
        condition,
      ].where((e) => e != null).length;

  Map<String, dynamic> toQuery() => {
        if (query != null && query!.isNotEmpty) 'q': query,
        if (categoryId != null) 'category_id': categoryId,
        if (province != null) 'province': province,
        if (district != null) 'district': district,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (condition != null) 'condition': condition,
        if (sort != null) 'sort': sort,
      };

  ProductFilters copyWith({
    String? query,
    String? categoryId,
    String? province,
    String? district,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? sort,
    bool clear = false,
  }) {
    if (clear) return const ProductFilters();
    return ProductFilters(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      province: province ?? this.province,
      district: district ?? this.district,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      condition: condition ?? this.condition,
      sort: sort ?? this.sort,
    );
  }
}

class ProductRepository {
  ProductRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<PaginatedResponse<ProductModel>> fetchProducts({
    int page = 1,
    ProductFilters filters = const ProductFilters(),
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      query: {
        'page': page,
        'per_page': AppConstants.pageSize,
        ...filters.toQuery(),
      },
    );
    return PaginatedResponse.fromJson(data, ProductModel.fromJson);
  }

  Future<List<ProductModel>> fetchFeatured() => _cachedList(
        cacheKey: CacheService.kHomeFeatured,
        path: ApiEndpoints.featuredProducts,
        parse: ProductModel.fromJson,
      );

  Future<List<ProductModel>> fetchRecommended() => _cachedList(
        cacheKey: CacheService.kHomeRecommended,
        path: ApiEndpoints.recommendedProducts,
        parse: ProductModel.fromJson,
      );

  Future<List<ProductModel>> fetchRelated(String productId) =>
      _fetchList(ApiEndpoints.relatedProducts(productId));

  Future<ProductModel> fetchDetail(String id) async {
    final cacheKey = CacheService.productDetail(id);
    try {
      final data = await _client
          .get<Map<String, dynamic>>(ApiEndpoints.productDetail(id));
      final map = (data['data'] ?? data) as Map<String, dynamic>;
      await CacheService.instance.write(cacheKey, map);
      return ProductModel.fromJson(map);
    } on ApiException {
      final cached = CacheService.instance.readMap(cacheKey);
      if (cached != null) return ProductModel.fromJson(cached);
      rethrow;
    }
  }

  Future<List<CategoryModel>> fetchCategories() =>
      _cachedList(
        cacheKey: CacheService.kCategories,
        path: ApiEndpoints.categories,
        parse: CategoryModel.fromJson,
      );

  Future<List<BannerModel>> fetchBanners() => _cachedList(
        cacheKey: CacheService.kHomeBanners,
        path: ApiEndpoints.banners,
        parse: BannerModel.fromJson,
      );

  Future<List<ProductModel>> fetchFavorites() =>
      _fetchList(ApiEndpoints.favorites);

  Future<void> toggleFavorite(String productId, {required bool favorite}) =>
      favorite
          ? _client.post<void>(ApiEndpoints.favoriteToggle(productId))
          : _client.delete<void>(ApiEndpoints.favoriteToggle(productId));

  Future<List<ProductModel>> fetchMyListings() =>
      _fetchList(ApiEndpoints.myListings);

  Future<void> deleteListing(String productId) =>
      _client.delete<void>(ApiEndpoints.productDetail(productId));

  Future<List<ProductModel>> _fetchList(String path) async {
    final data = await _client.get<Map<String, dynamic>>(path);
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  /// Cache-then-network for a list endpoint: on success, refresh the cache and
  /// return live data; on network failure, fall back to the last cached copy.
  Future<List<T>> _cachedList<T>({
    required String cacheKey,
    required String path,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final data = await _client.get<Map<String, dynamic>>(path);
      final raw = (data['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      await CacheService.instance.write(cacheKey, raw);
      return raw.map(parse).toList();
    } on ApiException {
      final cached = CacheService.instance.readList(cacheKey);
      if (cached != null) return cached.map(parse).toList();
      rethrow;
    }
  }
}
