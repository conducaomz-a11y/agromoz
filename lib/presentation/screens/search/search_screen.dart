import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/base_view_state.dart';
import '../../../providers/search_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/user_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          controller: _controller,
          hintText: 'Produtos, agricultores, empresas…',
          elevation: const WidgetStatePropertyAll(0),
          leading: const Icon(Icons.search_rounded),
          trailing: [
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _controller.clear();
                  provider.clear();
                },
              ),
          ],
          onChanged: provider.onQueryChanged,
          onSubmitted: provider.submit,
        ),
      ),
      body: Column(
        children: [
          // ── Live suggestions ─────────────────────────
          if (provider.suggestions.isNotEmpty)
            Material(
              elevation: 1,
              child: Column(
                children: provider.suggestions
                    .take(6)
                    .map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.north_west_rounded,
                              size: 18),
                          title: Text(s),
                          onTap: () {
                            _controller.text = s;
                            provider.submit(s);
                          },
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: switch (provider.status) {
              ViewStatus.initial => const EmptyStateView(
                  icon: Icons.search_rounded,
                  title: 'Pesquise em todo o AgroMoz',
                  message:
                      'Encontre produtos, agricultores, empresas e categorias.',
                ),
              ViewStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              ViewStatus.error => ErrorStateView(
                  message: provider.error ?? '',
                  onRetry: provider.submit,
                ),
              ViewStatus.empty => EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'Sem resultados para "${provider.query}"',
                  message: 'Tente palavras diferentes ou mais gerais.',
                ),
              _ => ListView(
                  children: [
                    if (provider.result!.categories.isNotEmpty) ...[
                      const SectionHeader(title: 'Categorias'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          children: provider.result!.categories
                              .map((c) => ActionChip(
                                    label: Text(c.name),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.marketplace,
                                      arguments: c.id,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (provider.result!.farmers.isNotEmpty ||
                        provider.result!.companies.isNotEmpty) ...[
                      const SectionHeader(title: 'Agricultores e empresas'),
                      ...[
                        ...provider.result!.farmers,
                        ...provider.result!.companies,
                      ].map((u) => ListTile(
                            leading: UserAvatar(
                                name: u.name, imageUrl: u.avatarUrl),
                            title: Text(u.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text([
                              u.roleLabel,
                              if (u.province != null) u.province!,
                            ].join(' · ')),
                            trailing:
                                const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.farmerProfile,
                              arguments: u.id,
                            ),
                          )),
                    ],
                    if (provider.result!.products.isNotEmpty) ...[
                      const SectionHeader(title: 'Produtos'),
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
                        itemCount: provider.result!.products.length,
                        itemBuilder: (_, i) => ProductCard(
                          product: provider.result!.products[i],
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRouter.productDetail,
                            arguments: provider.result!.products[i].id,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}
