import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/article_model.dart';
import '../data/repositories/article_repository.dart';
import 'base_view_state.dart';

/// Lista de artigos educativos com paginação infinita e filtro por categoria.
class ArticlesProvider extends ChangeNotifier {
  ArticlesProvider({ArticleRepository? repository})
      : _repo = repository ?? ArticleRepository();

  final ArticleRepository _repo;

  ViewStatus status = ViewStatus.initial;
  String? error;

  final List<ArticleModel> articles = [];
  List<ArticleCategoryModel> categories = [];
  String? selectedCategoryId;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  Future<void> load() async {
    status = ViewStatus.loading;
    error = null;
    notifyListeners();
    try {
      final pageData =
          await _repo.fetchArticles(page: 1, categoryId: selectedCategoryId);
      if (categories.isEmpty) {
        try {
          categories = await _repo.fetchCategories();
        } on ApiException {
          // categorias são opcionais — a lista funciona sem elas
        }
      }
      articles
        ..clear()
        ..addAll(pageData.items);
      _page = 1;
      _hasMore = pageData.hasMore;
      status = articles.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on ApiException catch (e) {
      error = e.message;
      status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || status != ViewStatus.success) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final pageData = await _repo.fetchArticles(
        page: _page + 1,
        categoryId: selectedCategoryId,
      );
      _page++;
      articles.addAll(pageData.items);
      _hasMore = pageData.hasMore;
    } on ApiException {
      // silencioso — o utilizador pode tentar de novo ao voltar a rolar
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> selectCategory(String? id) async {
    if (selectedCategoryId == id) return;
    selectedCategoryId = id;
    await load();
  }

  /// Detalhe do artigo (conteúdo completo para abrir DENTRO da app).
  Future<ArticleModel> fetchArticle(String slugOrId) =>
      _repo.fetchArticle(slugOrId);
}
