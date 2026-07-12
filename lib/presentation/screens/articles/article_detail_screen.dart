import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/article_model.dart';
import '../../../providers/articles_provider.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/state_views.dart';

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

  void _retry() => setState(() {
        _future = context.read<ArticlesProvider>().fetchArticle(widget.slugOrId);
      });

  int _readingMinutes(String html) {
    final words = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return (words / 200).ceil().clamp(1, 60);
  }

  void _share(ArticleModel a) {
    final site = Uri.parse(ApiEndpoints.baseUrl).replace(path: '/artigo/${a.slug}');
    Share.share('${a.title}\n\nLê no AgroMoz: $site');
  }

  /// Divide o HTML em 3 partes iguais para intercalar banners.
  /// Corta nos limites de tags para não partir HTML a meio.
  List<String> _splitContent(String html) {
    if (html.length < 600) return [html]; // artigo curto: sem divisão

    // Divide em parágrafos usando </p> como delimitador.
    final paragraphs = html.split(RegExp(r'(?<=</p>)'));
    if (paragraphs.length < 4) return [html]; // poucos parágrafos: sem divisão

    final third = (paragraphs.length / 3).floor();
    final part1 = paragraphs.sublist(0, third).join();
    final part2 = paragraphs.sublist(third, third * 2).join();
    final part3 = paragraphs.sublist(third * 2).join();
    return [part1, part2, part3];
  }

  Map<String, Style> _htmlStyles(ColorScheme scheme) => {
        'body': Style(
          margin: Margins.zero,
          fontSize: FontSize(16.5),
          lineHeight: const LineHeight(1.75),
          color: scheme.onSurface,
        ),
        'p': Style(margin: Margins.only(bottom: 14)),
        'h1': Style(
          fontSize: FontSize(24),
          fontWeight: FontWeight.w800,
          margin: Margins.only(top: 18, bottom: 8),
        ),
        'h2': Style(
          fontSize: FontSize(21),
          fontWeight: FontWeight.w800,
          margin: Margins.only(top: 18, bottom: 8),
          color: scheme.primary,
        ),
        'h3': Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.w700,
          margin: Margins.only(top: 14, bottom: 6),
        ),
        'li': Style(margin: Margins.only(bottom: 6)),
        'blockquote': Style(
          margin: Margins.symmetric(vertical: 12),
          padding: HtmlPaddings.only(left: 14),
          border: Border(left: BorderSide(color: scheme.primary, width: 3)),
          fontStyle: FontStyle.italic,
          color: scheme.onSurfaceVariant,
        ),
        'img': Style(margin: Margins.symmetric(vertical: 10)),
        'a': Style(color: scheme.primary, textDecoration: TextDecoration.underline),
        'strong': Style(fontWeight: FontWeight.w700),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                message: 'Não foi possível carregar o artigo. Verifica a tua ligação.',
                onRetry: _retry,
              ),
            );
          }
          final a = snap.data!;
          final content =
              a.content?.isNotEmpty == true ? a.content! : '<p>${a.excerpt ?? ''}</p>';
          final minutes = _readingMinutes(content);
          final parts = _splitContent(content);
          final styles = _htmlStyles(scheme);

          return CustomScrollView(
            slivers: [
              // ── Capa com gradiente ──
              SliverAppBar(
                pinned: true,
                expandedHeight: a.imageUrl != null ? 280 : 120,
                backgroundColor: scheme.surface,
                iconTheme: IconThemeData(
                  color: a.imageUrl != null ? Colors.white : scheme.onSurface,
                ),
                actions: [
                  IconButton(
                    tooltip: 'Partilhar',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _share(a),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: a.imageUrl == null
                      ? null
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(url: a.imageUrl),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black38, Colors.transparent, Colors.black87],
                                  stops: [0, .45, 1],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16, right: 16, bottom: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (a.categoryName != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        a.categoryName!.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white, fontSize: 11,
                                          fontWeight: FontWeight.w800, letterSpacing: .6,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    a.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título (sem imagem de capa)
                      if (a.imageUrl == null) ...[
                        if (a.categoryName != null)
                          Text(
                            a.categoryName!.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          a.title,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Metadados
                      Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(
                          a.publishedAt != null ? Formatters.timeAgo(a.publishedAt!) : 'AgroMoz',
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule_rounded, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(
                          '$minutes min de leitura',
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Divider(color: scheme.outlineVariant.withValues(alpha: .5)),
                      const SizedBox(height: 6),

                      // ── Conteúdo com 3 banners intercalados ──
                      if (parts.length == 1)
                        // Artigo curto: conteúdo + 1 banner no fim
                        ...[
                          _HtmlBlock(data: parts[0], styles: styles, scheme: scheme),
                          const SizedBox(height: 20),
                          const _ArticleAdBanner(),
                        ]
                      else ...[
                        // Parte 1
                        _HtmlBlock(data: parts[0], styles: styles, scheme: scheme),
                        const _ArticleAdBanner(),

                        // Parte 2
                        _HtmlBlock(data: parts[1], styles: styles, scheme: scheme),
                        const _ArticleAdBanner(),

                        // Parte 3
                        _HtmlBlock(data: parts[2], styles: styles, scheme: scheme),
                        const SizedBox(height: 20),
                        // Banner no fim (3º banner)
                        const _ArticleAdBanner(),
                      ],

                      const SizedBox(height: 14),
                      Divider(color: scheme.outlineVariant.withValues(alpha: .5)),
                      const SizedBox(height: 14),

                      // Partilhar
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _share(a),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Partilhar este artigo'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '🌱 AgroMoz — Agricultura moderna em Moçambique',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
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

/// Bloco de HTML reutilizável com os estilos editoriais.
class _HtmlBlock extends StatelessWidget {
  const _HtmlBlock({required this.data, required this.styles, required this.scheme});
  final String data;
  final Map<String, Style> styles;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Html(
        data: data,
        style: styles,
        onLinkTap: (url, _, __) {
          if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
      );
}

/// Banner de anúncio com moldura subtil para separar do conteúdo editorial.
class _ArticleAdBanner extends StatelessWidget {
  const _ArticleAdBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Divider(color: scheme.outlineVariant.withValues(alpha: .3)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Publicidade',
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: .5),
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(child: AdBanner()),
          const SizedBox(height: 8),
          Divider(color: scheme.outlineVariant.withValues(alpha: .3)),
        ],
      ),
    );
  }
}
