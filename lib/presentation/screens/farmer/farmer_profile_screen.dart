import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/farmer_details.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/farmer_repository.dart';
import '../../../routes/app_router.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/product_card.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

/// Perfil público do Fornecedor (empresa do site) com paridade total:
/// capa, logo, descrição, contactos, WhatsApp, website, endereço,
/// horário, galeria de fotos, produtos e avaliações.
class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _repo = FarmerRepository();
  late Future<(FarmerDetails, List<ProductModel>, List<ReviewModel>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(FarmerDetails, List<ProductModel>, List<ReviewModel>)>
      _load() async {
    final results = await Future.wait([
      _repo.fetchFarmer(widget.farmerId),
      _repo.fetchFarmerProducts(widget.farmerId),
      _repo.fetchReviews(widget.farmerId),
    ]);
    return (
      results[0] as FarmerDetails,
      results[1] as List<ProductModel>,
      results[2] as List<ReviewModel>,
    );
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir.')),
        );
      }
    }
  }

  void _openMaps(FarmerDetails d) {
    final query = (d.latitude != null && d.longitude != null)
        ? '${d.latitude},${d.longitude}'
        : Uri.encodeComponent(
            [d.address, d.user.district, d.user.province]
                .whereType<String>()
                .join(', '),
          );
    _launch(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Fornecedor')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorStateView(
              message: snapshot.error?.toString() ?? 'Erro ao carregar perfil.',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final (details, products, reviews) = snapshot.data!;
          final farmer = details.user;
          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // ── Capa + logo sobreposto (como no site) ──
                      SizedBox(
                        height: 176,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: details.coverUrl != null &&
                                      details.coverUrl!.isNotEmpty
                                  ? AppNetworkImage(url: details.coverUrl)
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            scheme.primary,
                                            scheme.primary.withOpacity(.6),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: UserAvatar(
                                    name: farmer.name,
                                    imageUrl: farmer.avatarUrl,
                                    radius: 36,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          children: [
                            Text(farmer.name,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text(
                              [
                                farmer.roleLabel,
                                if (farmer.district != null &&
                                    farmer.district!.isNotEmpty)
                                  farmer.district!,
                                if (farmer.province != null &&
                                    farmer.province!.isNotEmpty)
                                  farmer.province!,
                              ].join(' · '),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RatingStars(rating: farmer.rating),
                                const SizedBox(width: 6),
                                Text(
                                  '${farmer.rating.toStringAsFixed(1)} · ${farmer.reviewCount} avaliações · ${details.views} visitas',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (farmer.bio != null &&
                                farmer.bio!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(farmer.bio!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 16),
                            // ── Acções: Ligar · WhatsApp · Mensagem ──
                            Row(
                              children: [
                                if (farmer.phone != null &&
                                    farmer.phone!.isNotEmpty)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _launch(
                                          Uri.parse('tel:${farmer.phone}')),
                                      icon: const Icon(Icons.call_rounded,
                                          size: 18),
                                      label: const Text('Ligar'),
                                    ),
                                  ),
                                if (details.whatsapp != null &&
                                    details.whatsapp!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        final digits = details.whatsapp!
                                            .replaceAll(RegExp(r'\D'), '');
                                        _launch(Uri.parse(
                                            'https://wa.me/$digits'));
                                      },
                                      icon: const Icon(Icons.chat_rounded,
                                          size: 18),
                                      label: const Text('WhatsApp'),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.chat,
                                      arguments: ChatArgs(
                                        conversationId:
                                            'seller_${farmer.id}',
                                        otherUser: farmer,
                                      ),
                                    ),
                                    icon: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 18),
                                    label: const Text('Mensagem'),
                                  ),
                                ),
                              ],
                            ),
                            // ── Informações (endereço, horário, web) ──
                            if (details.address != null ||
                                details.schedule != null ||
                                details.website != null ||
                                farmer.email != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest
                                      .withOpacity(.35),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    if (details.address != null &&
                                        details.address!.isNotEmpty)
                                      _InfoTile(
                                        icon: Icons.place_outlined,
                                        text: details.address!,
                                        onTap: () => _openMaps(details),
                                      ),
                                    if (details.schedule != null &&
                                        details.schedule!.isNotEmpty)
                                      _InfoTile(
                                        icon: Icons.schedule_rounded,
                                        text: details.schedule!,
                                      ),
                                    if (details.website != null &&
                                        details.website!.isNotEmpty)
                                      _InfoTile(
                                        icon: Icons.language_rounded,
                                        text: details.website!,
                                        onTap: () {
                                          var url = details.website!;
                                          if (!url.startsWith('http')) {
                                            url = 'https://$url';
                                          }
                                          _launch(Uri.parse(url));
                                        },
                                      ),
                                    if (farmer.email != null &&
                                        farmer.email!.isNotEmpty)
                                      _InfoTile(
                                        icon: Icons.mail_outline_rounded,
                                        text: farmer.email!,
                                        onTap: () => _launch(Uri.parse(
                                            'mailto:${farmer.email}')),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            // ── Galeria de fotos da empresa ──
                            if (details.gallery.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Galeria',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 96,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: details.gallery.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final img = details.gallery[i];
                                    return InkWell(
                                      onTap: () => _showPhoto(context, img),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 120,
                                          height: 96,
                                          child:
                                              AppNetworkImage(url: img.url),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      tabs: [
                        Tab(text: 'Produtos (${products.length})'),
                        Tab(text: 'Avaliações (${reviews.length})'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  products.isEmpty
                      ? const EmptyStateView(
                          icon: Icons.inventory_2_outlined,
                          title: 'Sem produtos publicados',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                        ),
                  reviews.isEmpty
                      ? const EmptyStateView(
                          icon: Icons.reviews_outlined,
                          title: 'Ainda sem avaliações',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = reviews[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        UserAvatar(
                                          name: r.authorName,
                                          imageUrl: r.authorAvatarUrl,
                                          radius: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(r.authorName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                        if (r.createdAt != null)
                                          Text(
                                            Formatters.timeAgo(r.createdAt!),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    RatingStars(rating: r.rating, size: 14),
                                    if (r.comment != null) ...[
                                      const SizedBox(height: 6),
                                      Text(r.comment!),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPhoto(BuildContext context, GalleryImage img) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: InteractiveViewer(
                child: AppNetworkImage(url: img.url, fit: BoxFit.contain),
              ),
            ),
            if (img.caption != null && img.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(img.caption!),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, size: 20, color: theme.colorScheme.primary),
      title: Text(text, style: theme.textTheme.bodyMedium),
      trailing: onTap != null
          ? Icon(Icons.open_in_new_rounded,
              size: 14, color: theme.colorScheme.onSurfaceVariant)
          : null,
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: tabBar,
      );

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
