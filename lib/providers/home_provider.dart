import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/article_model.dart';
import '../data/models/banner_model.dart';
import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/product_repository.dart';
import 'base_view_state.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider({ProductRepository? repository})
      : _repo = repository ?? ProductRepository();

  final ProductRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;

  List<BannerModel> banners = [];
  List<CategoryModel> categories = [];
  List<ProductModel> featured = [];
  List<ProductModel> latest = [];
  List<ProductModel> recommended = [];
  List<UserModel> companies = [];
  List<ArticleModel> articles = [];

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
        // Conteúdo do site — se estes endpoints falharem, a Home
        // continua a funcionar (listas vazias em vez de erro total).
        _repo
            .fetchCompanies()
            .catchError((Object _) => <UserModel>[]),
        _repo
            .fetchArticles()
            .catchError((Object _) => <ArticleModel>[]),
      ]);
      banners = results[0] as List<BannerModel>;
      categories = results[1] as List<CategoryModel>;
      featured = results[2] as List<ProductModel>;
      latest = (results[3] as dynamic).items as List<ProductModel>;
      recommended = results[4] as List<ProductModel>;
      companies = results[5] as List<UserModel>;
      articles = results[6] as List<ArticleModel>;
      status = ViewStatus.success;
      error = null;
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }
}
