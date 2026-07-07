import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/product_repository.dart';

/// Bottom sheet with all marketplace filters:
/// province, district, category, price range, condition.
class FiltersSheet extends StatefulWidget {
  const FiltersSheet({
    super.key,
    required this.current,
    required this.categories,
  });

  final ProductFilters current;
  final List<CategoryModel> categories;

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  String? _province;
  String? _categoryId;
  String? _condition;
  late final TextEditingController _district;
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;

  @override
  void initState() {
    super.initState();
    _province = widget.current.province;
    _categoryId = widget.current.categoryId;
    _condition = widget.current.condition;
    _district = TextEditingController(text: widget.current.district ?? '');
    _minPrice = TextEditingController(
        text: widget.current.minPrice?.toStringAsFixed(0) ?? '',);
    _maxPrice = TextEditingController(
        text: widget.current.maxPrice?.toStringAsFixed(0) ?? '',);
  }

  @override
  void dispose() {
    _district.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.pop(
      context,
      ProductFilters(
        query: widget.current.query,
        province: _province,
        district: _district.text.trim().isEmpty ? null : _district.text.trim(),
        categoryId: _categoryId,
        condition: _condition,
        minPrice: double.tryParse(_minPrice.text),
        maxPrice: double.tryParse(_maxPrice.text),
        sort: widget.current.sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filtros',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const ProductFilters()),
                  child: const Text('Limpar tudo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _province,
              decoration: const InputDecoration(labelText: 'Província'),
              items: AppConstants.provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _province = v),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _district,
              decoration: const InputDecoration(labelText: 'Distrito'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: widget.categories
                  .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)),)
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPrice,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Preço mín. (MT)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPrice,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Preço máx. (MT)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Estado do produto', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.productConditions.map((c) {
                final selected = _condition == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _condition = selected ? null : c),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _apply, child: const Text('Aplicar filtros')),
          ],
        ),
      ),
    );
  }
}
