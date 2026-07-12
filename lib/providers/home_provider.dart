import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/banner_model.dart';
import '../data/models/category_model.dart';
import '../data/models/paginated_response.dart';
import '../data/models/product_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/farmer_repository.dart';
import '../data/repositories/product_repository.dart';
import 'base_view_state.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider({ProductRepository? repository, FarmerRepository? farmerRepository})
      : _repo = repository ?? ProductRepository(),
        _farmerRepo = farmerRepository ?? FarmerRepository();

  final ProductRepository _repo;
  final FarmerRepository _farmerRepo;

  ViewStatus status = ViewStatus.initial;
  String? error;

  List<BannerModel> banners = [];
  List<CategoryModel> categories = [];
  List<ProductModel> featured = [];
  List<ProductModel> latest = [];
  List<ProductModel> recommended = [];
  List<UserModel> suppliers = [];

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      status = ViewStatus.loading;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        _repo.fetchBanners(),
        _repo.fetchCategories(),
        _repo.fetchFeatured(),
        _repo.fetchProducts(filters: const ProductFilters(sort: 'recent')),
        _repo.fetchRecommended(),
        _farmerRepo.fetchFarmers(page: 1).catchError(
              (_) => PaginatedResponse<UserModel>.empty(),
            ),
      ]);
      banners = results[0] as List<BannerModel>;
      categories = results[1] as List<CategoryModel>;
      featured = results[2] as List<ProductModel>;
      latest = (results[3] as dynamic).items as List<ProductModel>;
      recommended = results[4] as List<ProductModel>;
      suppliers = (results[5] as dynamic).items as List<UserModel>;
      status = ViewStatus.success;
      error = null;
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }
}
