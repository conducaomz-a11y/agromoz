import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/credits/credit_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/base_view_state.dart';
import '../../../providers/business_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/state_views.dart';
import 'business_edit_screen.dart';
import 'business_wizard_screen.dart';
import 'my_products_screen.dart';
import 'product_form_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _credits = 0;
  bool _earningCredit = false;

  // Temporizador de 30 minutos para crédito grátis
  Timer? _freeTimer;
  Duration _freeCountdown = const Duration(minutes: 30);
  bool _freeTimerRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<BusinessProvider>();
      if (p.status == ViewStatus.initial) p.load();
      await _refreshCredits();
      AdService.instance.preloadRewarded();
    });
  }

  @override
  void dispose() {
    _freeTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshCredits() async {
    final bal = await CreditService.instance.fetchBalance();
    if (mounted) setState(() => _credits = bal);
  }

  /// Ganha 1 crédito vendo anúncio rewarded.
  Future<void> _ganharCredito() async {
    if (_earningCredit) return;

    if (!AdService.instance.isRewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anúncio a carregar. Tenta daqui a pouco.')),
      );
      AdService.instance.preloadRewarded();
      return;
    }

    setState(() => _earningCredit = true);

    bool ganhou = false;
    final mostrou = await AdService.instance.showRewarded(
      onReward: () async {
        ganhou = true;
        await CreditService.instance.addCreditsFromAd();
      },
    );

    if (!mounted) return;
    setState(() => _earningCredit = false);
    await _refreshCredits();

    if (!mostrou) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível mostrar o anúncio.')),
      );
    } else if (!ganhou) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vê o anúncio até ao fim para ganhar o crédito.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 +1 crédito ganho!')),
      );
    }
  }

  /// Inicia temporizador de 30 min para ganhar 1 crédito grátis.
  void _iniciarTimerGratis() {
    if (_freeTimerRunning) return;
    setState(() {
      _freeTimerRunning = true;
      _freeCountdown = const Duration(minutes: 30);
    });

    _freeTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) { t.cancel(); return; }
      final novoTemp = _freeCountdown - const Duration(seconds: 1);
      if (novoTemp <= Duration.zero) {
        t.cancel();
        await CreditService.instance.addCreditsFromAd();
        if (!mounted) return;
        setState(() {
          _freeTimerRunning = false;
          _freeCountdown = const Duration(minutes: 30);
        });
        await _refreshCredits();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎁 +1 crédito grátis ganho!')),
        );
      } else {
        setState(() => _freeCountdown = novoTemp);
      }
    });
  }

  String _formatCountdown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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

  Future<void> _editarEmpresa() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BusinessEditScreen()),
    );
    if (updated == true && mounted) {
      context.read<BusinessProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BusinessProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Negócio'),
        actions: [
          if (p.hasBusiness)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar Empresa',
              onPressed: _editarEmpresa,
            ),
        ],
      ),
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
                    color: Colors.amber.withValues(alpha: .18),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, color: Colors.amber),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A tua página ainda está em revisão pela equipa AgroMoz.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // ── Estatísticas ──
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.9,
                  children: [
                    _StatCard(value: '${p.stats?.totalProducts ?? 0}', label: 'Produtos/Serviços'),
                    _StatCard(value: '${p.stats?.available ?? 0}', label: 'Disponíveis', color: Colors.green),
                    _StatCard(value: '${p.stats?.runningOut ?? 0}', label: 'A Esgotar', color: Colors.orange),
                    _StatCard(value: '${p.stats?.pageViews ?? 0}', label: 'Visitas à Página'),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Card de créditos de IA ──
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: .3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Créditos de IA',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _credits > 0
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      size: 16,
                                      color: _credits > 0
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onErrorContainer),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_credits crédito${_credits == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _credits > 0
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usa créditos para gerar descrições de produtos com IA.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        // Botões para ganhar créditos
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _earningCredit ? null : _ganharCredito,
                                icon: _earningCredit
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.play_circle_outline, size: 18),
                                label: const Text('Ver anúncio\n+1 crédito',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _freeTimerRunning
                                  ? OutlinedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(Icons.timer_outlined, size: 18),
                                      label: Text(
                                        'Grátis em\n${_formatCountdown(_freeCountdown)}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: _iniciarTimerGratis,
                                      icon: const Icon(Icons.hourglass_empty_rounded, size: 18),
                                      label: const Text('Esperar 30 min\n+1 crédito grátis',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12)),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                            child: AppNetworkImage(url: p.business!.logoUrl),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.business!.name,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              Text(p.business!.typeLabel,
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Editar',
                          onPressed: _editarEmpresa,
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
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyProductsScreen())),
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
                          const Text('Ainda não adicionaste produtos ou serviços.'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ProductFormScreen())),
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
                              url: prod.images.isNotEmpty ? prod.images.first : null,
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
                              builder: (_) => ProductFormScreen(product: prod)),
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
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProductFormScreen())),
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
                    fontWeight: FontWeight.w800, color: color)),
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
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
