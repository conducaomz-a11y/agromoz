import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/articles_provider.dart';
import '../../../providers/base_view_state.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/state_views.dart';
import 'article_detail_screen.dart';

/// Aba "Aprender" — artigos educativos do site, lidos dentro da app.
class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ArticlesProvider>();
      if (p.status == ViewStatus.initial) p.load();
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - 300) {
      context.read<ArticlesProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArticlesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aprender')),
      body: switch (p.status) {
        ViewStatus.initial ||
        ViewStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        ViewStatus.error => ErrorStateView(
            message: p.error ?? '',
            onRetry: p.load,
          ),
        ViewStatus.empty => EmptyStateView(
            icon: Icons.menu_book_outlined,
            title: 'Ainda não há artigos',
            message: 'Volta em breve — estamos a preparar conteúdo novo.',
            actionLabel: 'Actualizar',
            onAction: p.load,
          ),
        _ => RefreshIndicator(
            onRefresh: p.load,
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                // ── Filtro por categoria ──
                if (p.categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          _CategoryChip(
                            label: 'Todos',
                            selected: p.selectedCategoryId == null,
                            onTap: () => p.selectCategory(null),
                          ),
                          for (final c in p.categories)
                            _CategoryChip(
                              label: c.name,
                              selected: p.selectedCategoryId == c.id,
                              onTap: () => p.selectCategory(c.id),
                            ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount:
                        p.articles.length + (p.loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i >= p.articles.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final a = p.articles[i];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArticleDetailScreen(slugOrId: a.slug),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (a.imageUrl != null)
                                AspectRatio(
                                  aspectRatio: 16 / 8,
                                  child: AppNetworkImage(url: a.imageUrl),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${a.categoryName ?? 'Sem categoria'}'
                                      '${a.publishedAt != null ? ' · ${Formatters.timeAgo(a.publishedAt!)}' : ''}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      a.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    if (a.excerpt != null &&
                                        a.excerpt!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        a.excerpt!,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
