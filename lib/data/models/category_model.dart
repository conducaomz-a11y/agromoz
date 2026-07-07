class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String? iconUrl;
  final int productCount;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        iconUrl: json['icon_url'] as String?,
        productCount: (json['product_count'] as num?)?.toInt() ?? 0,
      );
}
