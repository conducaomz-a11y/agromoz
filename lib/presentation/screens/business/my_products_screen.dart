import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../providers/business_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/state_views.dart';
import 'product_form_screen.dart';

/// "Os Meus Produtos e Serviços" — igual ao site: toggle rápido de
/// disponibilidade, editar e eliminar com confirmação.
class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final provider = context.read<BusinessProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar produto?'),
        content: const Text('Esta acção não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await provider.deleteProduct(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Produto eliminado.'
              : provider.error ?? 'Falha ao eliminar.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BusinessProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Os Meus Produtos e Serviços')),
      body: p.products.isEmpty
          ? EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: 'Ainda não tens produtos cadastrados',
              message: 'Adiciona o teu primeiro produto ou serviço.',
              actionLabel: 'Novo Produto',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              ),
            )
          : RefreshIndicator(
              onRefresh: p.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: p.products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final prod = p.products[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 68,
                              height: 68,
                              child: AppNetworkImage(
                                url: prod.images.isNotEmpty
                                    ? prod.images.first
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prod.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(
                                  prod.price != null
                                      ? '${Formatters.price(prod.price!)}'
                                          '${prod.unit?.isNotEmpty == true ? ' · ${prod.unit}' : ''}'
                                      : 'Sob consulta',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                // ── Toggle rápido de disponibilidade ──
                                _AvailabilityDropdown(
                                  value: prod.availability,
                                  onChanged: (v) async {
                                    final provider =
                                        context.read<BusinessProvider>();
                                    final ok = await provider
                                        .setAvailability(prod.id, v);
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(provider.error ??
                                            'Falha ao actualizar.'),
                                      ));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductFormScreen(product: prod),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red),
                                onPressed: () =>
                                    _confirmDelete(context, prod.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Produto'),
      ),
    );
  }
}

class _AvailabilityDropdown extends StatelessWidget {
  const _AvailabilityDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = {
    'disponivel': '✅ Disponível',
    'esgotando': '⚠️ A Esgotar',
    'indisponivel': '❌ Indisponível',
  };

  @override
  Widget build(BuildContext context) {
    final color = switch (value) {
      'esgotando' => Colors.orange,
      'indisponivel' => Colors.red,
      _ => Colors.green,
    };
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final e in _options.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_options[value] ?? value,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
