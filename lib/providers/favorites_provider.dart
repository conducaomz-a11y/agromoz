import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';
import 'base_view_state.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({ProductRepository? repository})
      : _repo = repository ?? ProductRepository();

  final ProductRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;
  List<ProductModel> favorites = [];

  /// Limpa os dados ao trocar de conta.
  void reset() {
    favorites = [];
    status = ViewStatus.initial;
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    status = ViewStatus.loading;
    notifyListeners();
    try {
      favorites = await _repo.fetchFavorites();
      status = favorites.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> remove(ProductModel product) async {
    favorites.removeWhere((p) => p.id == product.id);
    if (favorites.isEmpty) status = ViewStatus.empty;
    notifyListeners();
    try {
      await _repo.toggleFavorite(product.id, favorite: false);
    } on ApiException {
      favorites.add(product);
      status = ViewStatus.success;
      notifyListeners();
    }
  }
}
