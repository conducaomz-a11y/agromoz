import 'package:flutter/material.dart';

import '../../../core/utils/contact_launcher.dart';
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

  /// Folha de avaliação: estrelas 1-5 + comentário opcional.
  Future<void> _openReviewSheet(UserModel farmer) async {
    int rating = 5;
    final comment = TextEditingController();
    bool sending = false;

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Avaliar ${farmer.name}',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      iconSize: 36,
                      onPressed: () => setSheet(() => rating = i),
                      icon: Icon(
                        i <= rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        setSheet(() => sending = true);
                        try {
                          await _repo.postReview(
                            farmerId: widget.farmerId,
                            rating: rating,
                            comment: comment.text.trim().isEmpty
                                ? null
                                : comment.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setSheet(() => sending = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Enviar avaliação'),
              ),
            ],
          ),
        ),
      ),
    );

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obrigado pela tua avaliação! ⭐')),
      );
      setState(() => _future = _load()); // recarrega para mostrar a review
    }
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (farmer.phone != null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    ContactLauncher.call(context, farmer.phone!),
                                icon: const Icon(Icons.call_outlined),
                                label: const Text('Ligar'),
                              ),
                            if (farmer.phone != null)
                              const SizedBox(width: 10),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => ContactLauncher.openWhatsApp(
                                context,
                                phone: farmer.whatsapp ?? farmer.phone ?? '',
                                message:
                                    'Olá! Encontrei a vossa página no AgroMoz.',
                              ),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('WhatsApp'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _openReviewSheet(farmer),
                          icon: const Icon(Icons.star_outline_rounded),
                          label: const Text('Avaliar esta página'),
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
