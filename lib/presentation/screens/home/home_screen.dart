import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/article_model.dart';
import '../../../data/models/user_model.dart';

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
                // Search bar → jumps to Search tab experience.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SearchBar(
                    hintText: 'Pesquisar produtos, agricultores…',
                    leading: const Icon(Icons.search_rounded),
                    elevation: const WidgetStatePropertyAll(0),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.search),
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
                // ── Artigos do blog do site ───────────────────────
                if (home.articles.isNotEmpty) ...[
                  const SectionHeader(title: 'Notícias e dicas'),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: home.articles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _ArticleCard(article: home.articles[i]),
                  ),
                ],
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
                // ── Empresas do site (mesma base de dados) ────────
                if (home.companies.isNotEmpty) ...[
                  const SectionHeader(title: 'Empresas em destaque'),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: home.companies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _CompanyCard(
                        company: home.companies[i],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.farmerProfile,
                          arguments: home.companies[i].id,
                        ),
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


/// Cartão horizontal de empresa (logo + nome + província).
/// Toque abre o perfil público (mesmo ecrã do vendedor).
class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.company, required this.onTap});

  final UserModel company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withOpacity(.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.primaryContainer,
              backgroundImage:
                  company.avatarUrl != null && company.avatarUrl!.isNotEmpty
                      ? NetworkImage(company.avatarUrl!)
                      : null,
              child: company.avatarUrl == null || company.avatarUrl!.isEmpty
                  ? Icon(Icons.storefront_rounded, color: scheme.primary)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              company.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700, height: 1.15),
            ),
            if (company.province != null && company.province!.isNotEmpty)
              Text(
                company.province!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de artigo do blog — abre o artigo no site, no navegador.
class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final ArticleModel article;

  Future<void> _open() async {
    final uri = Uri.tryParse(article.url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withOpacity(.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 96,
                child: article.imageUrl != null && article.imageUrl!.isNotEmpty
                    ? AppNetworkImage(url: article.imageUrl)
                    : Container(
                        color: scheme.primaryContainer,
                        child:
                            Icon(Icons.article_rounded, color: scheme.primary),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.categoryName != null)
                    Text(
                      article.categoryName!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                  ),
                  if (article.excerpt != null &&
                      article.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.excerpt!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Ler no site',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
