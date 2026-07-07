import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/search_repository.dart';
import 'base_view_state.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider({SearchRepository? repository})
      : _repo = repository ?? SearchRepository();

  final SearchRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;
  String query = '';
  List<String> suggestions = [];
  GlobalSearchResult? result;

  Timer? _debounce;

  /// Live suggestions with a 350 ms debounce.
  void onQueryChanged(String value) {
    query = value;
    _debounce?.cancel();
    if (value.trim().length < 2) {
      suggestions = [];
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        suggestions = await _repo.suggestions(value.trim());
        notifyListeners();
      } on ApiException {
        // suggestions are best-effort
      }
    });
  }

  Future<void> submit([String? value]) async {
    final q = (value ?? query).trim();
    if (q.isEmpty) return;
    query = q;
    suggestions = [];
    status = ViewStatus.loading;
    notifyListeners();
    try {
      result = await _repo.search(q);
      status = result!.isEmpty ? ViewStatus.empty : ViewStatus.success;
      error = null;
    } on ApiException catch (e) {
      status = ViewStatus.error;
      error = e.message;
    }
    notifyListeners();
  }

  void clear() {
    query = '';
    suggestions = [];
    result = null;
    status = ViewStatus.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
