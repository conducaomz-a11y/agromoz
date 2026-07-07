class BannerModel {
  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.targetUrl,
    this.productId,
  });

  final String id;
  final String imageUrl;
  final String? title;
  final String? targetUrl;
  final String? productId;

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        id: json['id'].toString(),
        imageUrl: json['image_url'] as String? ?? '',
        title: json['title'] as String?,
        targetUrl: json['target_url'] as String?,
        productId: json['product_id']?.toString(),
      );
}
