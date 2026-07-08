import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/business_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/state_views.dart';
import 'business_edit_screen.dart';
import 'business_wizard_screen.dart';
import 'my_products_screen.dart';
import 'product_form_screen.dart';

/// Painel profissional — igual ao /profissional/dashboard do site:
/// alerta de revisão, cartões de estatísticas e produtos recentes.
class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BusinessProvider>();
      if (p.status == ViewStatus.initial) p.load();
    });
  }

  Future<void> _openWizard() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BusinessWizardScreen()),
    );
    if (created == true && mounted) {
      context.read<BusinessProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BusinessProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Negócio')),
      body: switch (p.status) {
        ViewStatus.initial ||
        ViewStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        ViewStatus.error => ErrorStateView(
            message: p.error ?? '',
            onRetry: p.load,
          ),
        _ when !p.hasBusiness => EmptyStateView(
            icon: Icons.storefront_outlined,
            title: 'Cria a tua Página de Negócio',
            message:
                'És agricultor, avicultor ou fornecedor de insumos? Cria a tua '
                'página grátis e começa a vender no AgroMoz.',
            actionLabel: '🌱 Criar Página de Negócio',
            onAction: _openWizard,
          ),
        _ => RefreshIndicator(
            onRefresh: p.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Alerta: em revisão ──
                if (p.business!.isPending)
                  Card(
                    color: Colors.amber.withOpacity(.18),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              color: Colors.amber),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A tua página ainda está em revisão pela '
                              'equipa AgroMoz.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // ── Cartões de estatísticas ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.9,
                  children: [
                    _StatCard(
                      value: '${p.stats?.totalProducts ?? 0}',
                      label: 'Produtos/Serviços',
                    ),
                    _StatCard(
                      value: '${p.stats?.available ?? 0}',
                      label: 'Disponíveis',
                      color: Colors.green,
                    ),
                    _StatCard(
                      value: '${p.stats?.runningOut ?? 0}',
                      label: 'A Esgotar',
                      color: Colors.orange,
                    ),
                    _StatCard(
                      value: '${p.stats?.pageViews ?? 0}',
                      label: 'Visitas à Página',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Resumo da empresa ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child:
                                AppNetworkImage(url: p.business!.logoUrl),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.business!.name,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700)),
                              Text(p.business!.typeLabel,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Produtos recentes ──
                Row(
                  children: [
                    Text('Produtos Recentes',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyProductsScreen()),
                      ),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Gerir Produtos'),
                    ),
                  ],
                ),
                if (p.products.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 40),
                          const SizedBox(height: 8),
                          const Text(
                              'Ainda não adicionaste produtos ou serviços.'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ProductFormScreen()),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Adicionar Primeiro Produto'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final prod in p.products.take(6))
                    Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: AppNetworkImage(
                              url: prod.images.isNotEmpty
                                  ? prod.images.first
                                  : null,
                            ),
                          ),
                        ),
                        title: Text(prod.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(prod.price != null
                            ? Formatters.price(prod.price!)
                            : 'Sob consulta'),
                        trailing: _AvailabilityBadge(prod.availability),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductFormScreen(product: prod),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
      },
      floatingActionButton: p.hasBusiness
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo Produto'),
            )
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
            Text(label,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge(this.availability);
  final String availability;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (availability) {
      'esgotando' => ('⚠️ A Esgotar', Colors.orange),
      'indisponivel' => ('❌ Indisponível', Colors.red),
      _ => ('✅ Disponível', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
