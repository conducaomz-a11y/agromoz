import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/articles_provider.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/app_network_image.dart';
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
  final _searchCtrl = TextEditingController();

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _submitSearch(String text) {
    final q = text.trim();
    Navigator.pushNamed(
      context,
      AppRouter.marketplace,
      arguments: q.isEmpty ? null : MarketplaceArgs(query: q),
    );
    _searchCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final articles = context.watch<ArticlesProvider>().articles;
    final unread = context.watch<NotificationProvider>().unreadCount;
    final hasBusiness = context.watch<BusinessProvider>().hasBusiness;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => home.load(refresh: true),
        child: switch (home.status) {
          ViewStatus.loading || ViewStatus.initial => const _HomeShimmer(),
          ViewStatus.error => ErrorStateView(
              message: home.error ?? '',
              onRetry: () => home.load(),
            ),
          _ => ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ═══ HEADER VERDE ═══
                _GreenHeader(
                  searchController: _searchCtrl,
                  onSearch: _submitSearch,
                  unread: unread,
                  onBellTap: () =>
                      Navigator.pushNamed(context, AppRouter.notifications),
                ),

                // ═══ CATEGORIAS (cartões com ícone) ═══
                if (home.categories.any((c) => c.productCount > 0)) ...[
                  const SizedBox(height: 16),
                  _CategoryRow(
                    categories: home.categories
                        .where((c) => c.productCount > 0)
                        .toList(),
                  ),
                ],

                // ═══ ANÚNCIOS EM DESTAQUE ═══
                if (home.featured.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Anúncios em destaque',
                    onSeeAll: () =>
                        Navigator.pushNamed(context, AppRouter.marketplace),
                  ),
                  _HorizontalProducts(products: home.featured),
                ],

                // ═══ PRODUTOS ═══
                if (home.latest.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Produtos',
                    onSeeAll: () =>
                        Navigator.pushNamed(context, AppRouter.marketplace),
                  ),
                  _HorizontalProducts(products: home.latest),
                ],
                if (home.recommended.isNotEmpty) ...[
                  const SectionHeader(title: 'Recomendados para si'),
                  _ProductGrid(products: home.recommended),
                ],

                // ═══ ARTIGOS ═══
                if (articles.isNotEmpty) ...[
                  const SectionHeader(title: 'Artigos'),
                  _ArticlesList(articles: articles.take(4).toList()),
                ],

                // ═══ EMPRESAS ═══
                if (home.suppliers.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Empresas e produtores',
                    onSeeAll: () =>
                        Navigator.pushNamed(context, AppRouter.marketplace),
                  ),
                  _SuppliersRow(suppliers: home.suppliers),
                ],

                // ═══ Banner de anúncio ═══
                const AdBanner(),

                // ═══ CTA: só para quem NÃO tem loja ═══
                if (!hasBusiness) const _SellCta(),

                const SizedBox(height: 24),
              ],
            ),
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// HEADER VERDE (título + subtítulo + pesquisa + sino)
// ══════════════════════════════════════════════════════
class _GreenHeader extends StatelessWidget {
  const _GreenHeader({
    required this.searchController,
    required this.onSearch,
    required this.unread,
    required this.onBellTap,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final int unread;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Imagem de fundo (fallback: só o gradiente se faltar).
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_header.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // Véu verde por cima, para o texto continuar legível.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: .92),
                    AppColors.primary.withValues(alpha: .82),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 24),
            child: _headerContent(context),
          ),
        ],
      ),
    );
  }

  Widget _headerContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Logo + sino
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 34,
                height: 34,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 8),
              const Text(
                'AgroMoz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.white.withValues(alpha: .15),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBellTap,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Compre e venda\nprodutos agrícolas\nem Moçambique',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'De agricultores para o mundo.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .9),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          // Barra de pesquisa
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar produtos, categorias...',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => onSearch(searchController.text),
                  ),
                ),
              ),
            ),
          ),
        ],
    );
  }
}

// ══════════════════════════════════════════════════════
// CATEGORIAS (cartões brancos com ícone grande)
// ══════════════════════════════════════════════════════
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories});
  final List categories;

  // Emoji por nome de categoria (fallback para as da imagem).
  String _emojiFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('grão') || n.contains('grao') || n.contains('cereal')) {
      return '🌽';
    }
    if (n.contains('hort') || n.contains('legume') || n.contains('verd')) {
      return '🥬';
    }
    if (n.contains('fruta')) return '🍎';
    if (n.contains('aves') || n.contains('galinh') || n.contains('frango')) {
      return '🐔';
    }
    if (n.contains('gado') || n.contains('carne') || n.contains('boi')) {
      return '🐄';
    }
    return '📦';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = categories[i];
          return _CategoryCard(
            name: c.name,
            emoji: _emojiFor(c.name),
            iconUrl: c.iconUrl,
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.marketplace,
              arguments: c.id,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.emoji,
    required this.onTap,
    this.iconUrl,
  });

  final String name;
  final String emoji;
  final String? iconUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: iconUrl != null && iconUrl!.isNotEmpty
                  ? AppNetworkImage(url: iconUrl)
                  : Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// PRODUTOS horizontais
// ══════════════════════════════════════════════════════
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

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});
  final List products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .72,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(
        product: products[i],
        onTap: () => Navigator.pushNamed(
          context,
          AppRouter.productDetail,
          arguments: products[i].id,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// ARTIGOS
// ══════════════════════════════════════════════════════
class _ArticlesList extends StatelessWidget {
  const _ArticlesList({required this.articles});
  final List articles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final a in articles)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(slugOrId: a.slug),
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
                                  color: theme.colorScheme.primaryContainer,
                                  child: Icon(Icons.article_outlined,
                                      color: theme.colorScheme.primary),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (a.categoryName != null)
                              Text(
                                a.categoryName!.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            Text(
                              a.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text('Ler na app',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
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
    );
  }
}

// ══════════════════════════════════════════════════════
// EMPRESAS
// ══════════════════════════════════════════════════════
class _SuppliersRow extends StatelessWidget {
  const _SuppliersRow({required this.suppliers});
  final List suppliers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suppliers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = suppliers[i];
          return _SupplierCard(
            name: s.name,
            avatarUrl: s.avatarUrl,
            location: [s.district, s.province]
                .where((e) => e != null && e.isNotEmpty)
                .join(', '),
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.farmerProfile,
              arguments: s.id,
            ),
          );
        },
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.name,
    required this.location,
    required this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String location;
  final VoidCallback onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 130,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? AppNetworkImage(url: avatarUrl)
                      : Icon(Icons.storefront_rounded,
                          color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// CTA vender (só para quem não tem loja)
// ══════════════════════════════════════════════════════
class _SellCta extends StatelessWidget {
  const _SellCta();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                      color: theme.colorScheme.onPrimaryContainer)),
              const SizedBox(height: 6),
              Text(
                'Cria a tua página de negócio grátis e chega a compradores '
                'em todo Moçambique.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.businessDashboard),
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Criar Página de Negócio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Shimmer de carregamento
// ══════════════════════════════════════════════════════
class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        ShimmerBox(height: 180, radius: 18),
        SizedBox(height: 20),
        ShimmerBox(width: 160, height: 20),
        SizedBox(height: 12),
        ProductGridShimmer(count: 4),
      ],
    );
  }
}
