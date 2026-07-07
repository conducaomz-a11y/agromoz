class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.province,
    this.district,
    this.bio,
    this.role = 'farmer',
    this.rating = 0,
    this.reviewCount = 0,
    this.productCount = 0,
    this.isOnline = false,
    this.memberSince,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? province;
  final String? district;
  final String? bio;

  /// farmer | buyer | company | supplier | service_provider
  final String role;
  final double rating;
  final int reviewCount;
  final int productCount;
  final bool isOnline;
  final DateTime? memberSince;

  String get roleLabel {
    switch (role) {
      case 'buyer':
        return 'Comprador';
      case 'company':
        return 'Empresa Agrícola';
      case 'supplier':
        return 'Fornecedor';
      case 'service_provider':
        return 'Prestador de Serviços';
      default:
        return 'Agricultor';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        province: json['province'] as String?,
        district: json['district'] as String?,
        bio: json['bio'] as String?,
        role: json['role'] as String? ?? 'farmer',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        productCount: (json['product_count'] as num?)?.toInt() ?? 0,
        isOnline: json['is_online'] as bool? ?? false,
        memberSince: json['member_since'] != null
            ? DateTime.tryParse(json['member_since'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'province': province,
        'district': district,
        'bio': bio,
      };
}
