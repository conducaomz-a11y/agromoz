/// Central registry of every REST endpoint the app consumes.
///
/// Replace [baseUrl] with the real AgroMoz API host. All paths below are
/// paths match the appapi (PHP) backend deployed at agromoz.com.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://agromoz.com/appapi/v1';

  // ── Auth ──────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String verifyEmail = '/verify-email';
  static const String resendCode = '/resend-code';
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

  // ── Articles (abrem dentro da app) ────────────────────
  static const String articles = '/articles';
  static const String articleCategories = '/articles/categories';
  static String articleDetail(String slugOrId) => '/articles/$slugOrId';

  // ── Business (fluxo profissional) ─────────────────────
  static const String business = '/business';
  static const String businessUpdate = '/business/update';
  static const String businessStats = '/business/stats';
  static const String businessTypes = '/business/types';
  static const String businessProducts = '/business/products';
  static String businessProduct(String id) => '/business/products/$id';
  static String businessProductAvailability(String id) =>
      '/business/products/$id/availability';
  static String farmerReviewCreate(String id) => '/farmers/$id/reviews';

  // ── Misc ──────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String deviceToken = '/devices'; // FCM registration
}
