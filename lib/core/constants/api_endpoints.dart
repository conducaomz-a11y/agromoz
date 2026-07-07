/// Central registry of every REST endpoint the app consumes.
///
/// Replace [baseUrl] with the real AgroMoz API host. All paths below are
/// placeholders that mirror the expected contract — swap them in one place.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://agromoz.com/appapi/v1';

  // ── Auth ──────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String refreshToken = '/refresh-token';
  static const String logout = '/logout';

  // ── Catalog ───────────────────────────────────────────
  static const String products = '/products';
  static const String categories = '/categories';
  static const String featuredProducts = '/products/featured';
  static const String recommendedProducts = '/products/recommended';
  static const String banners = '/banners';
  static String productDetail(String id) => '/products/$id';
  static String relatedProducts(String id) => '/products/$id/related';

  // ── Users / Farmers ───────────────────────────────────
  static const String profile = '/profile';
  static const String changePassword = '/profile/password';
  static const String myListings = '/profile/listings';
  static const String favorites = '/favorites';
  static String favoriteToggle(String productId) => '/favorites/$productId';
  static String farmerProfile(String id) => '/farmers/$id';
  static String farmerReviews(String id) => '/farmers/$id/reviews';

  // ── Messaging ─────────────────────────────────────────
  static const String conversations = '/messages';
  static String conversationMessages(String id) => '/messages/$id';
  static String sendMessage(String id) => '/messages/$id';

  // ── Misc ──────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String searchSuggestions = '/search/suggestions';
  static const String deviceToken = '/devices'; // FCM registration
}
