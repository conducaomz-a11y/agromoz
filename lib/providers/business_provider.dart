import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/business_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/business_repository.dart';
import 'base_view_state.dart';

/// Estado do fluxo profissional: a minha empresa, estatísticas e produtos.
class BusinessProvider extends ChangeNotifier {
  BusinessProvider({BusinessRepository? repository})
      : _repo = repository ?? BusinessRepository();

  final BusinessRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;
  bool isBusy = false;

  BusinessModel? business;
  BusinessStatsModel? stats;
  List<OwnProductModel> products = [];
  List<BusinessTypeModel> types = [];

  bool get hasBusiness => business != null;

  /// Carrega a empresa (se existir) + estatísticas + produtos.
  Future<void> load() async {
    status = ViewStatus.loading;
    error = null;
    notifyListeners();
    try {
      business = await _repo.fetchMyBusiness();
      if (business != null) {
        stats = await _repo.fetchStats();
        products = await _repo.fetchMyProducts();
      }
      status = ViewStatus.success;
    } on ApiException catch (e) {
      error = e.message;
      status = ViewStatus.error;
    } catch (_) {
      error = 'Não foi possível carregar o teu negócio. Tenta novamente.';
      status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<List<BusinessTypeModel>> loadTypes() async {
    if (types.isEmpty) types = await _repo.fetchTypes();
    return types;
  }

  Future<List<CategoryModel>> categoriesForType(String type) =>
      _repo.fetchCategoriesForType(type);

  Future<bool> createBusiness(BusinessInput input) => _run(() async {
        business = await _repo.createBusiness(input);
        stats = await _repo.fetchStats();
      });

  Future<bool> updateBusiness(BusinessInput input) => _run(() async {
        business = await _repo.updateBusiness(input);
      });

  Future<bool> saveProduct({String? id, required ProductInput input}) =>
      _run(() async {
        final saved = id == null
            ? await _repo.createProduct(input)
            : await _repo.updateProduct(id, input);
        final idx = products.indexWhere((p) => p.id == saved.id);
        if (idx >= 0) {
          products[idx] = saved;
        } else {
          products.insert(0, saved);
        }
        stats = await _repo.fetchStats();
      });

  Future<bool> setAvailability(String id, String availability) =>
      _run(() async {
        final updated = await _repo.setAvailability(id, availability);
        final idx = products.indexWhere((p) => p.id == id);
        if (idx >= 0) products[idx] = updated;
      });

  Future<bool> deleteProduct(String id) => _run(() async {
        await _repo.deleteProduct(id);
        products.removeWhere((p) => p.id == id);
        stats = await _repo.fetchStats();
      });

  void reset() {
    business = null;
    stats = null;
    products = [];
    status = ViewStatus.initial;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
