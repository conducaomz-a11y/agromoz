import 'package:flutter/material.dart';

import '../presentation/screens/articles/article_detail_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/otp_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/business/business_dashboard_screen.dart';
import '../presentation/screens/business/business_edit_screen.dart';
import '../presentation/screens/business/business_wizard_screen.dart';
import '../presentation/screens/business/my_products_screen.dart';
import '../presentation/screens/farmer/farmer_profile_screen.dart';
import '../presentation/screens/main_shell.dart';
import '../presentation/screens/marketplace/marketplace_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/product/product_detail_screen.dart';
import '../presentation/screens/profile/change_password_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/favorites_screen.dart';
import '../presentation/screens/profile/settings_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';

/// Named routes for the whole app.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String main = '/main';
  static const String marketplace = '/marketplace';
  static const String productDetail = '/product';
  static const String farmerProfile = '/farmer';
  static const String articleDetail = '/article';
  static const String notifications = '/notifications';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/password';
  static const String favorites = '/profile/favorites';
  static const String settings = '/profile/settings';
  static const String businessDashboard = '/business';
  static const String businessWizard = '/business/create';
  static const String businessEdit = '/business/edit';
  static const String myProducts = '/business/products';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case splash:
        return _page(const SplashScreen(), settings);
      case onboarding:
        return _page(const OnboardingScreen(), settings);
      case login:
        return _page(const LoginScreen(), settings);
      case register:
        return _page(const RegisterScreen(), settings);
      case forgotPassword:
        return _page(const ForgotPasswordScreen(), settings);
      case otp:
        return _page(OtpScreen(identifier: args as String? ?? ''), settings);
      case main:
        return _page(const MainShell(), settings);
      case marketplace:
        return _page(
          MarketplaceScreen(initialCategoryId: args as String?),
          settings,
        );
      case productDetail:
        return _page(
          ProductDetailScreen(productId: args as String? ?? ''),
          settings,
        );
      case farmerProfile:
        return _page(
          FarmerProfileScreen(farmerId: args as String? ?? ''),
          settings,
        );
      case articleDetail:
        return _page(
          ArticleDetailScreen(slugOrId: args as String? ?? ''),
          settings,
        );
      case notifications:
        return _page(const NotificationsScreen(), settings);
      case editProfile:
        return _page(const EditProfileScreen(), settings);
      case changePassword:
        return _page(const ChangePasswordScreen(), settings);
      case favorites:
        return _page(const FavoritesScreen(), settings);
      case businessDashboard:
        return _page(const BusinessDashboardScreen(), settings);
      case businessWizard:
        return _page(const BusinessWizardScreen(), settings);
      case businessEdit:
        return _page(const BusinessEditScreen(), settings);
      case myProducts:
        return _page(const MyProductsScreen(), settings);
      case AppRouter.settings:
        return _page(const SettingsScreen(), settings);
      default:
        return _page(
          const Scaffold(body: Center(child: Text('Rota não encontrada'))),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) =>
      MaterialPageRoute(builder: (_) => child, settings: settings);
}
