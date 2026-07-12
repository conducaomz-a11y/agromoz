import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/product_detail_provider.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../routes/app_router.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/product_card.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _gallery = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProductDetailProvider>().load(widget.productId),
    );
  }

  @override
  void dispose() {
    _gallery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductDetailProvider>();
    final theme = Theme.of(context);
    final product = provider.product;

    if (provider.status.isLoading || product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: provider.status.isError
            ? ErrorStateView(
                message: provider.error ?? '',
                onRetry: () => provider.load(widget.productId),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Partilhar',
            onPressed: () => Share.share(
              '${product.title} — ${Formatters.price(product.price)} no AgroMoz',
            ),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: product.isFavorite
                ? 'Remover dos favoritos'
                : 'Guardar nos favoritos',
            onPressed: provider.toggleFavorite,
            icon: Icon(
              product.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              color: product.isFavorite ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Gallery ──────────────────────────────────
          SizedBox(
            height: 300,
            child: product.images.isEmpty
                ? const AppNetworkImage(url: null)
                : PageView.builder(
                    controller: _gallery,
                    itemCount: product.images.length,
                    itemBuilder: (_, i) => Hero(
                      tag: i == 0 ? 'product_${product.id}' : 'img_$i',
                      child: AppNetworkImage(url: product.images[i]),
                    ),
                  ),
          ),
          if (product.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: SmoothPageIndicator(
                  controller: _gallery,
                  count: product.images.length,
                  effect: WormEffect(
                    dotHeight: 7,
                    dotWidth: 7,
                    activeDotColor: theme.colorScheme.primary,
                    dotColor: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  Formatters.price(product.price) +
                      (product.unit != null ? ' / ${product.unit}' : ''),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (product.categoryName != null)
                      Chip(label: Text(product.categoryName!)),
                    if (product.condition != null)
                      Chip(label: Text(product.condition!)),
                    Chip(
                      avatar: Icon(
                        product.isAvailable
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 18,
                      ),
                      label: Text(product.isAvailable
                          ? 'Disponível'
                          : 'Indisponível'),
                    ),
                    if (product.locationLabel.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.place_outlined, size: 18),
                        label: Text(product.locationLabel),
                      ),
                  ],
                ),
                if (product.quantityAvailable != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Quantidade disponível: ${product.quantityAvailable!.toStringAsFixed(0)} ${product.unit ?? ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (product.cycle != null) ...[
                  const SizedBox(height: 16),
                  _CycleCard(cycle: product.cycle!),
                ],
                if (product.description != null) ...[
                  const SizedBox(height: 16),
                  Text('Descrição',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(product.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
                // ── Seller card ─────────────────────────
                if (product.seller != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.farmerProfile,
                        arguments: product.seller!.id,
                      ),
                      leading: UserAvatar(
                        name: product.seller!.name,
                        imageUrl: product.seller!.avatarUrl,
                      ),
                      title: Text(product.seller!.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Row(
                        children: [
                          RatingStars(
                              rating: product.seller!.rating, size: 14),
                          const SizedBox(width: 6),
                          Text('(${product.seller!.reviewCount})'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (provider.related.isNotEmpty) ...[
            const SectionHeader(title: 'Produtos relacionados'),
            SizedBox(
              height: 235,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: provider.related[i],
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRouter.productDetail,
                      arguments: provider.related[i].id,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
      // ── Contact bar ──────────────────────────────────
      bottomNavigationBar: product.seller == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    if (product.seller!.phone != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri(scheme: 'tel', path: product.seller!.phone),
                          ),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Ligar'),
                        ),
                      ),
                    if (product.seller!.phone != null)
                      const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => ContactLauncher.openWhatsApp(
                          context,
                          phone: product.seller!.whatsapp ??
                              product.seller!.phone ??
                              '',
                          message: 'Olá! Vi o produto "${product.title}" '
                              'no AgroMoz e gostaria de saber mais.',
                        ),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Cartão do ciclo de vida (colheita/reposição) com contador de dias.
class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.cycle});

  final ProductCycle cycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cor conforme o tipo/estado.
    final Color color;
    final IconData icon;
    if (cycle.isSoldOut) {
      color = theme.colorScheme.error;
      icon = Icons.cancel_outlined;
    } else if (cycle.isReady) {
      color = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline;
    } else {
      color = cycle.isHarvest ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
      icon = cycle.isHarvest ? Icons.local_florist_outlined : Icons.inventory_2_outlined;
    }

    final days = cycle.daysRemaining;
    final showCountdown = cycle.isGrowing && days != null && days > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cycle.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showCountdown) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$days',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  days == 1 ? 'dia restante' : 'dias restantes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (cycle.availableFrom != null) ...[
              const SizedBox(height: 4),
              Text(
                'Disponível a partir de ${Formatters.date(cycle.availableFrom!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
