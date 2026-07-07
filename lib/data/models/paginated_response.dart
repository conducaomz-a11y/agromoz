/// Generic wrapper for paginated API responses.
/// Expected shape: { "data": [...], "meta": { "current_page": 1, "last_page": 5 } }
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedResponse(
      items: list,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
    );
  }
}
