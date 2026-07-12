import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/base_view_state.dart';
import '../../../providers/suppliers_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// Aba "Fornecedores" — directório público de empresas/páginas de negócio.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SuppliersProvider>();
      if (p.status == ViewStatus.initial) p.load();
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      context.read<SuppliersProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SuppliersProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fornecedores')),
      body: Column(
        children: [
          const AdBanner(),
          // ── Pesquisa ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              controller: _search,
              hintText: 'Pesquisar empresas…',
              leading: const Icon(Icons.search_rounded),
              elevation: const WidgetStatePropertyAll(0),
              onSubmitted: (v) => p.search(v),
              trailing: [
                if (_search.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      p.search('');
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          // ── Filtro por tipo ──
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: p.selectedType == null,
                    onSelected: (_) => p.selectType(null),
                  ),
                ),
                for (final e in SuppliersProvider.types.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e.value),
                      selected: p.selectedType == e.key,
                      onSelected: (_) => p.selectType(e.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── Lista ──
          Expanded(
            child: switch (p.status) {
              ViewStatus.initial ||
              ViewStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              ViewStatus.error => ErrorStateView(
                  message: p.error ?? 'Não foi possível carregar os fornecedores.',
                  onRetry: p.load,
                ),
              ViewStatus.empty => EmptyStateView(
                  icon: Icons.storefront_outlined,
                  title: 'Nenhum fornecedor encontrado',
                  message:
                      'Experimenta outro filtro — ou cria a tua própria página de negócio!',
                  actionLabel: '🌱 Criar Página de Negócio',
                  onAction: () => Navigator.pushNamed(
                      context, AppRouter.businessDashboard),
                ),
              _ => RefreshIndicator(
                  onRefresh: p.load,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount:
                        p.suppliers.length + (p.loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i >= p.suppliers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final s = p.suppliers[i];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.farmerProfile,
                            arguments: s.id,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                UserAvatar(
                                  name: s.name,
                                  imageUrl: s.avatarUrl,
                                  radius: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        [
                                          s.roleLabel,
                                          if (s.province != null) s.province!,
                                        ].join(' · '),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          RatingStars(
                                              rating: s.rating, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${s.rating.toStringAsFixed(1)}'
                                            ' · ${s.productCount} produtos',
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}
