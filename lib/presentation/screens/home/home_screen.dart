import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_box.dart';
import '../../widgets/state_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<HomeProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final user = context.watch<AuthProvider>().user;
    final unread = context.watch<NotificationProvider>().unreadCount;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${user?.name.split(' ').first ?? 'visitante'} 👋',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('O que procura hoje?',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => home.load(refresh: true),
        child: switch (home.status) {
          ViewStatus.loading || ViewStatus.initial => const _HomeShimmer(),
          ViewStatus.error => ErrorStateView(
              message: home.error ?? '',
              onRetry: () => home.load(),
            ),
          _ => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Barra de pesquisa → abre o Marketplace (que tem pesquisa
                // e filtros próprios); a aba dedicada de pesquisa foi removida.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SearchBar(
                    hintText: 'Pesquisar produtos…',
                    leading: const Icon(Icons.search_rounded),
                    elevation: const WidgetStatePropertyAll(0),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.marketplace),
                  ),
                ),
                const SizedBox(height: 12),
                BannerCarousel(
                  banners: home.banners,
                  onTap: (b) {
                    if (b.productId != null) {
                      Navigator.pushNamed(
                        context,
                        AppRouter.productDetail,
                        arguments: b.productId,
                      );
                    }
                  },
                ),
                if (home.categories.isNotEmpty) ...[
                  const SectionHeader(title: 'Categorias'),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: home.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final c = home.categories[i];
                        return _CategoryBubble(
                          name: c.name,
                          iconUrl: c.iconUrl,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.marketplace,
                            arguments: c.id,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (home.featured.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Produtos em destaque',
                    onSeeAll: () =>
                        Navigator.pushNamed(context, AppRouter.marketplace),
                  ),
                  _HorizontalProducts(products: home.featured),
                ],
                if (home.latest.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Últimos anúncios',
                    onSeeAll: () =>
                        Navigator.pushNamed(context, AppRouter.marketplace),
                  ),
                  _HorizontalProducts(products: home.latest),
                ],
                if (home.recommended.isNotEmpty) ...[
                  const SectionHeader(title: 'Recomendados para si'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: .72,
                    ),
                    itemCount: home.recommended.length,
                    itemBuilder: (_, i) => ProductCard(
                      product: home.recommended[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.productDetail,
                        arguments: home.recommended[i].id,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
        },
      ),
    );
  }
}

class _HorizontalProducts extends StatelessWidget {
  const _HorizontalProducts({required this.products});
  final List products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 235,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(
          width: 160,
          child: ProductCard(
            product: products[i],
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.productDetail,
              arguments: products[i].id,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({
    required this.name,
    this.iconUrl,
    required this.onTap,
  });

  final String name;
  final String? iconUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: iconUrl != null && iconUrl!.isNotEmpty
                  ? AppNetworkImage(url: iconUrl)
                  : Icon(Icons.eco_rounded, color: scheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerBox(height: 52, radius: 26),
        SizedBox(height: 16),
        ShimmerBox(height: 150, radius: 18),
        SizedBox(height: 24),
        ShimmerBox(width: 160, height: 20),
        SizedBox(height: 12),
        ProductGridShimmer(count: 4),
      ],
    );
  }
}
