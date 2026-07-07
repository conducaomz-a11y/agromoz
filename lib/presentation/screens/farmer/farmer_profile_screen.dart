import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/farmer_repository.dart';
import '../../../routes/app_router.dart';
import '../../widgets/product_card.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _repo = FarmerRepository();
  late Future<(UserModel, List<ProductModel>, List<ReviewModel>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(UserModel, List<ProductModel>, List<ReviewModel>)> _load() async {
    final results = await Future.wait([
      _repo.fetchFarmer(widget.farmerId),
      _repo.fetchFarmerProducts(widget.farmerId),
      _repo.fetchReviews(widget.farmerId),
    ]);
    return (
      results[0] as UserModel,
      results[1] as List<ProductModel>,
      results[2] as List<ReviewModel>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
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
          final (farmer, products, reviews) = snapshot.data!;
          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        UserAvatar(
                          name: farmer.name,
                          imageUrl: farmer.avatarUrl,
                          radius: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(farmer.name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                          [
                            farmer.roleLabel,
                            if (farmer.province != null) farmer.province!,
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RatingStars(rating: farmer.rating),
                            const SizedBox(width: 6),
                            Text(
                              '${farmer.rating.toStringAsFixed(1)} · ${farmer.reviewCount} avaliações',
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
                        FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRouter.chat,
                            arguments: ChatArgs(
                              conversationId: 'seller_${farmer.id}',
                              otherUser: farmer,
                            ),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Contactar'),
                        ),
                      ],
                    ),
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
