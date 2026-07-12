import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/ad_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();

    // Carrega auth + espera mínimo visual (800ms) em paralelo.
    // O App Open Ad mostra-se ENQUANTO o utilizador espera → experiência fluida.
    await Future.wait([
      auth.bootstrap(),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);

    if (!mounted) return;

    // Mostra o App Open Ad depois do splash estar pronto.
    // O ad sobrepõe-se ao ecrã de carregamento — exatamente como definido
    // no AdMob para este formato.
    await AdService.instance.showAppOpenAd();

    if (!mounted) return;

    if (auth.status == AuthStatus.authenticated) {
      Navigator.pushReplacementNamed(context, AppRouter.main);
    } else if (!auth.onboardingSeen) {
      Navigator.pushReplacementNamed(context, AppRouter.onboarding);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: .85, end: 1).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 88,
                    height: 88,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.agriculture_rounded,
                        size: 64,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'AgroMoz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'O mercado agrícola de Moçambique',
                  style: TextStyle(color: Colors.white.withValues(alpha: .85)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
