import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/base_view_state.dart';
import '../../../providers/favorites_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FavoritesProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoritesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: switch (provider.status) {
          ViewStatus.loading || ViewStatus.initial =>
            const Center(child: CircularProgressIndicator()),
          ViewStatus.error => ErrorStateView(
              message: provider.error ?? '',
              onRetry: provider.load,
            ),
          ViewStatus.empty => const EmptyStateView(
              icon: Icons.favorite_outline_rounded,
              title: 'Sem favoritos guardados',
              message:
                  'Toque no coração de um produto para o guardar aqui.',
            ),
          _ => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: provider.favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final p = provider.favorites[i];
                return Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => provider.remove(p),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,),
                  ),
                  child: ProductListTile(
                    product: p,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.productDetail,
                      arguments: p.id,
                    ),
                  ),
                );
              },
            ),
        },
      ),
    );
  }
}
