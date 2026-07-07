class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.authorName,
    required this.rating,
    this.authorAvatarUrl,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final double rating;
  final String? comment;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'].toString(),
        authorName: json['author_name'] as String? ?? 'Utilizador',
        authorAvatarUrl: json['author_avatar_url'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}
