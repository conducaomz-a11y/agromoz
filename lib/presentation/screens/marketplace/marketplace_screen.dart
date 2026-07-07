import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/product_repository.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/state_views.dart';
import 'filters_sheet.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MarketplaceProvider>();
      if (widget.initialCategoryId != null) {
        provider.applyFilters(
          provider.filters.copyWith(categoryId: widget.initialCategoryId),
        );
      } else if (provider.status == ViewStatus.initial) {
        provider.load();
      }
    });
  }

  void _onScroll() {
    // Infinite scrolling: fetch the next page near the end of the list.
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      context.read<MarketplaceProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final provider = context.read<MarketplaceProvider>();
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FiltersSheet(
        current: provider.filters,
        categories: provider.categories,
      ),
    );
    if (result != null) await provider.applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketplaceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado'),
        actions: [
          IconButton(
            tooltip: provider.isGridView ? 'Ver em lista' : 'Ver em grelha',
            onPressed: provider.toggleLayout,
            icon: Icon(provider.isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
          ),
          IconButton(
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: provider.filters.activeCount > 0,
              label: Text('${provider.filters.activeCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(refresh: true),
        child: switch (provider.status) {
          ViewStatus.loading ||
          ViewStatus.initial =>
            const SingleChildScrollView(child: ProductGridShimmer()),
          ViewStatus.error => ErrorStateView(
              message: provider.error ?? '',
              onRetry: () => provider.load(),
            ),
          ViewStatus.empty => EmptyStateView(
              icon: Icons.storefront_outlined,
              title: 'Nenhum produto encontrado',
              message:
                  'Ajuste os filtros ou volte mais tarde — novos anúncios são publicados todos os dias.',
              actionLabel: provider.filters.isEmpty ? null : 'Limpar filtros',
              onAction: provider.filters.isEmpty
                  ? null
                  : () => provider
                      .applyFilters(const ProductFilters()),
            ),
          _ => provider.isGridView
              ? GridView.builder(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .72,
                  ),
                  itemCount: provider.products.length +
                      (provider.status.isLoadingMore ? 2 : 0),
                  itemBuilder: (_, i) {
                    if (i >= provider.products.length) {
                      return const ShimmerBox(
                          height: double.infinity, radius: 16);
                    }
                    final p = provider.products[i];
                    return ProductCard(
                      product: p,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.productDetail,
                        arguments: p.id,
                      ),
                    );
                  },
                )
              : ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.products.length +
                      (provider.status.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    if (i >= provider.products.length) {
                      return const ShimmerBox(height: 110, radius: 16);
                    }
                    final p = provider.products[i];
                    return ProductListTile(
                      product: p,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.productDetail,
                        arguments: p.id,
                      ),
                    );
                  },
                ),
        },
      ),
    );
  }
}

