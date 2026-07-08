import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/article_model.dart';
import '../../../providers/articles_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/state_views.dart';

/// Leitura do artigo COMPLETO dentro da app — o utilizador não sai
/// para o browser.
class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key, required this.slugOrId});

  final String slugOrId;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Future<ArticleModel> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ArticlesProvider>().fetchArticle(widget.slugOrId);
  }

  void _retry() {
    setState(() {
      _future =
          context.read<ArticlesProvider>().fetchArticle(widget.slugOrId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: FutureBuilder<ArticleModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return SafeArea(
              child: ErrorStateView(
                message: snap.error?.toString() ??
                    'Não foi possível carregar o artigo.',
                onRetry: _retry,
              ),
            );
          }
          final a = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: a.imageUrl != null ? 220 : null,
                flexibleSpace: a.imageUrl != null
                    ? FlexibleSpaceBar(
                        background: AppNetworkImage(url: a.imageUrl),
                      )
                    : null,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => Share.share(a.title),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.categoryName ?? 'Artigo'}'
                        '${a.publishedAt != null ? ' · ${Formatters.timeAgo(a.publishedAt!)}' : ''}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      // ── Conteúdo HTML renderizado DENTRO da app ──
                      Html(
                        data: a.content?.isNotEmpty == true
                            ? a.content!
                            : '<p>${a.excerpt ?? ''}</p>',
                        style: {
                          'body': Style(
                            margin: Margins.zero,
                            fontSize: FontSize(16),
                            lineHeight: const LineHeight(1.6),
                          ),
                          'img': Style(margin: Margins.symmetric(vertical: 8)),
                        },
                        onLinkTap: (url, _, __) {
                          if (url != null) {
                            launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
