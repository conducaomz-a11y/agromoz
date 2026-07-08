import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/articles_provider.dart';
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
import '../articles/article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().load();
      final articles = context.read<ArticlesProvider>();
      if (articles.status == ViewStatus.initial) articles.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final articles = context.watch<ArticlesProvider>().articles;
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
                if (home.categories.any((c) => c.productCount > 0)) ...[
                  const SectionHeader(title: 'Categorias'),
                  SizedBox(
                    height: 100,
                    child: Builder(builder: (context) {
                      // Long page de venda: só categorias COM produtos.
                      final cats = home.categories
                          .where((c) => c.productCount > 0)
                          .toList();
                      return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final c = cats[i];
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
                    );
                    }),
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
                if (articles.isNotEmpty) ...[
                  const SectionHeader(title: 'Notícias e dicas'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (final a in articles.take(4))
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArticleDetailScreen(slugOrId: a.slug),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 84,
                                        height: 70,
                                        child: a.imageUrl != null
                                            ? AppNetworkImage(url: a.imageUrl)
                                            : Container(
                                                color: theme.colorScheme
                                                    .primaryContainer,
                                                child: Icon(Icons.article_outlined,
                                                    color: theme
                                                        .colorScheme.primary),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (a.categoryName != null)
                                            Text(
                                              a.categoryName!.toUpperCase(),
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          Text(
                                            a.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Ler na app',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
                // ── CTA: convite a vender na AgroMoz ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🌱 Tens produtos para vender?',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme
                                      .colorScheme.onPrimaryContainer)),
                          const SizedBox(height: 6),
                          Text(
                            'Cria a tua página de negócio grátis e chega a '
                            'compradores em todo Moçambique.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRouter.businessDashboard),
                            icon: const Icon(Icons.storefront_rounded),
                            label: const Text('Criar Página de Negócio'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
