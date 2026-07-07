import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';
import 'base_view_state.dart';

class ProductDetailProvider extends ChangeNotifier {
  ProductDetailProvider({ProductRepository? repository})
      : _repo = repository ?? ProductRepository();

  final ProductRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;
  ProductModel? product;
  List<ProductModel> related = [];

  Future<void> load(String id) async {
    status = ViewStatus.loading;
    notifyListeners();
    try {
      product = await _repo.fetchDetail(id);
      status = ViewStatus.success;
      notifyListeners();
      // Related products load after the main content — non-blocking.
      related = await _repo.fetchRelated(id);
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final current = product;
    if (current == null) return;
    // Optimistic update.
    product = current.copyWith(isFavorite: !current.isFavorite);
    notifyListeners();
    try {
      await _repo.toggleFavorite(current.id, favorite: !current.isFavorite);
    } on ApiException {
      product = current; // revert
      notifyListeners();
    }
  }
}
