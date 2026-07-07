import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/paginated_response.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../routes/app_router.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// Directório de Fornecedores — equivalente ao /diretorio do site.
/// Lista as empresas registadas com pesquisa e filtro por tipo de perfil.
class FornecedoresScreen extends StatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  final _repo = ProductRepository();
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<UserModel> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  String _query = '';
  String? _tipo; // tipo_perfil do site (null = todos)

  /// Mesmos tipos de perfil das empresas do site.
  static const _tipos = <(String?, String)>[
    (null, 'Todos'),
    ('agricultor', 'Agricultores'),
    ('horticultor', 'Horticultores'),
    ('avicultor', 'Avicultores'),
    ('cunicultor', 'Cunicultores'),
    ('vendedor_insumos', 'Insumos'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >
          _scroll.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final PaginatedResponse<UserModel> res = await _repo.fetchCompaniesPage(
        page: 1,
        q: _query,
        tipo: _tipo,
      );
      _items
        ..clear()
        ..addAll(res.items);
      _page = res.currentPage;
      _lastPage = res.lastPage;
    } catch (e) {
      _error = 'Não foi possível carregar os fornecedores.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _repo.fetchCompaniesPage(
        page: _page + 1,
        q: _query,
        tipo: _tipo,
      );
      _items.addAll(res.items);
      _page = res.currentPage;
      _lastPage = res.lastPage;
    } catch (_) {
      // silencioso: o utilizador pode voltar a fazer scroll para tentar
    }
    if (mounted) setState(() => _loadingMore = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _query = value.trim();
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Fornecedores')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Pesquisar empresas…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _tipos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _tipos[i];
                final selected = _tipo == value;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _tipo = value);
                    _load();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorStateView(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? const EmptyStateView(
                            icon: Icons.storefront_outlined,
                            title: 'Nenhum fornecedor encontrado',
                            subtitle:
                                'Tente outra pesquisa ou outro tipo de perfil.',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              controller: _scroll,
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  _items.length + (_loadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                if (i >= _items.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _CompanyTile(company: _items[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company});

  final UserModel company;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.farmerProfile,
        arguments: company.id,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withOpacity(.5)),
        ),
        child: Row(
          children: [
            UserAvatar(
              name: company.name,
              imageUrl: company.avatarUrl,
              radius: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    [
                      company.roleLabel,
                      if (company.province != null &&
                          company.province!.isNotEmpty)
                        company.province!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingStars(rating: company.rating, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${company.productCount} produto${company.productCount == 1 ? '' : 's'}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
