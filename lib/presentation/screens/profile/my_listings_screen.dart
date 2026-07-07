import 'package:flutter/material.dart';

import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../routes/app_router.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _repo = ProductRepository();
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchMyListings();
  }

  void _reload() => setState(() => _future = _repo.fetchMyListings());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus anúncios')),
      body: FutureBuilder<List<ProductModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: 'Ainda sem anúncios',
              message:
                  'Publique o seu primeiro produto para começar a vender.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => ProductListTile(
                product: products[i],
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.productDetail,
                  arguments: products[i].id,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
