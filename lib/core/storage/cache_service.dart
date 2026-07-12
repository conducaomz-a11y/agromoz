import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight key/value cache backed by Hive.
///
/// Repositories use this to implement a *cache-then-network* strategy:
/// return the last saved payload instantly (so the UI paints without waiting),
/// then refresh from the API and overwrite the cache. If the network is down,
/// the cached copy is what the user sees — the app stays usable offline.
///
/// Values are stored as JSON strings keyed by an endpoint-derived key, each
/// wrapped with a timestamp so callers can decide whether a copy is too stale.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const String _boxName = 'agromoz_cache';
  Box<String>? _box;

  /// Call once during app start (before runApp) — see main.dart.
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  bool get _ready => _box != null;

  /// Store any JSON-encodable value under [key].
  Future<void> write(String key, Object value) async {
    if (!_ready) return;
    final envelope = jsonEncode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'data': value,
    });
    await _box!.put(key, envelope);
  }

  /// Read a previously cached value. Returns null if missing/undecodable or
  /// older than [maxAge] (when provided).
  dynamic read(String key, {Duration? maxAge}) {
    if (!_ready) return null;
    final raw = _box!.get(key);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> envelope =
          jsonDecode(raw) as Map<String, dynamic>;
      if (maxAge != null) {
        final ts = envelope['ts'] as int? ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age > maxAge.inMilliseconds) return null;
      }
      return envelope['data'];
    } catch (_) {
      return null;
    }
  }

  /// Read a cached list of maps (the most common shape for our lists).
  List<Map<String, dynamic>>? readList(String key, {Duration? maxAge}) {
    final data = read(key, maxAge: maxAge);
    if (data is! List) return null;
    return data.whereType<Map<String, dynamic>>().toList();
  }

  /// Read a cached single map.
  Map<String, dynamic>? readMap(String key, {Duration? maxAge}) {
    final data = read(key, maxAge: maxAge);
    return data is Map<String, dynamic> ? data : null;
  }

  Future<void> remove(String key) async {
    if (_ready) await _box!.delete(key);
  }

  /// Wipe everything — call on logout so the next account starts clean.
  Future<void> clear() async {
    if (_ready) await _box!.clear();
  }

  /// Cache keys, centralised to avoid typos across repositories.
  static const String kHomeBanners = 'home:banners';
  static const String kHomeCategories = 'home:categories';
  static const String kHomeFeatured = 'home:featured';
  static const String kHomeLatest = 'home:latest';
  static const String kHomeRecommended = 'home:recommended';
  static const String kCategories = 'catalog:categories';
  static const String kArticles = 'articles:list';
  static String productList(String signature) => 'products:$signature';
  static String productDetail(String id) => 'product:$id';
  static String articleDetail(String id) => 'article:$id';
}
