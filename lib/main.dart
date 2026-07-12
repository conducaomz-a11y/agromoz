import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/cache_service.dart';
import 'providers/auth_provider.dart';
import 'providers/articles_provider.dart';
import 'providers/business_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/home_provider.dart';
import 'providers/marketplace_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/product_detail_provider.dart';
import 'providers/suppliers_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CacheService.instance.init();
  await LocalNotificationService.instance.init();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await PushNotificationService.instance.start();
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase not configured yet: $e');
  }

  try {
    await AdService.instance.init();
  } catch (e) {
    if (kDebugMode) debugPrint('AdMob init falhou: $e');
  }

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => ProductDetailProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => SuppliersProvider()),
        ChangeNotifierProvider(create: (_) => ArticlesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const AgroMozApp(),
    ),
  );
}
