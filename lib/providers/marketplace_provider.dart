import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';
import 'base_view_state.dart';

class MarketplaceProvider extends ChangeNotifier {
  MarketplaceProvider({ProductRepository? repository})
      : _repo = repository ?? ProductRepository();

  final ProductRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;

  final List<ProductModel> products = [];
  List<CategoryModel> categories = [];
  ProductFilters filters = const ProductFilters();
  bool isGridView = true;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  void toggleLayout() {
    isGridView = !isGridView;
    notifyListeners();
  }

  Future<void> applyFilters(ProductFilters next) async {
    filters = next;
    await load();
  }

  Future<void> load({bool refresh = false}) async {
    _page = 1;
    _hasMore = true;
    if (!refresh) {
      status = ViewStatus.loading;
      notifyListeners();
    }
    try {
      if (categories.isEmpty) {
        categories = await _repo.fetchCategories();
      }
      final page = await _repo.fetchProducts(page: _page, filters: filters);
      products
        ..clear()
        ..addAll(page.items);
      _hasMore = page.hasMore;
      status = products.isEmpty ? ViewStatus.empty : ViewStatus.success;
      error = null;
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || status.isLoadingMore || status.isLoading) return;
    status = ViewStatus.loadingMore;
    notifyListeners();
    try {
      _page += 1;
      final page = await _repo.fetchProducts(page: _page, filters: filters);
      products.addAll(page.items);
      _hasMore = page.hasMore;
      status = ViewStatus.success;
    } on ApiException {
      _page -= 1; // allow retry
      status = ViewStatus.success;
    }
    notifyListeners();
  }
}
