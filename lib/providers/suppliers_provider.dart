import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/user_model.dart';
import '../data/repositories/farmer_repository.dart';
import 'base_view_state.dart';

/// Aba "Fornecedores" — lista pública de empresas com filtro por tipo
/// de perfil e pesquisa por nome.
class SuppliersProvider extends ChangeNotifier {
  SuppliersProvider({FarmerRepository? repository})
      : _repo = repository ?? FarmerRepository();

  final FarmerRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;

  final List<UserModel> suppliers = [];
  String? selectedType; // null → todos
  String query = '';

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  static const types = <String, String>{
    'agricultor': 'Agricultores',
    'horticultor': 'Horticultores',
    'avicultor': 'Avicultores',
    'cunicultor': 'Cunicultores',
    'vendedor_insumos': 'Fornecedores de Insumos',
  };

  Future<void> load() async {
    status = ViewStatus.loading;
    error = null;
    notifyListeners();
    try {
      final page = await _repo.fetchFarmers(
        page: 1,
        type: selectedType,
        query: query,
      );
      suppliers
        ..clear()
        ..addAll(page.items);
      _page = 1;
      _hasMore = page.hasMore;
      status = suppliers.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on ApiException catch (e) {
      error = e.message;
      status = ViewStatus.error;
    } catch (_) {
      error = 'Não foi possível carregar os fornecedores. Tenta novamente.';
      status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || status != ViewStatus.success) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _repo.fetchFarmers(
        page: _page + 1,
        type: selectedType,
        query: query,
      );
      _page++;
      suppliers.addAll(page.items);
      _hasMore = page.hasMore;
    } on ApiException {
      // silencioso
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> selectType(String? type) async {
    if (selectedType == type) return;
    selectedType = type;
    await load();
  }

  Future<void> search(String text) async {
    query = text.trim();
    await load();
  }
}
