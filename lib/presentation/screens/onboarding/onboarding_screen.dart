import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      Icons.storefront_rounded,
      'Venda directamente da sua machamba',
      'Publique os seus produtos e alcance compradores em todas as províncias de Moçambique.',
    ),
    _Slide(
      Icons.search_rounded,
      'Encontre o que precisa, perto de si',
      'Pesquise produtos agrícolas por província, distrito, categoria e preço.',
    ),
    _Slide(
      Icons.chat_rounded,
      'Negocie em segurança',
      'Converse com agricultores, empresas e fornecedores dentro da aplicação.',
    ),
  ];

  Future<void> _finish() async {
    await context.read<AuthProvider>().markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Saltar'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 72,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(s.icon,
                              size: 72, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        Text(s.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _slides.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: theme.colorScheme.primary,
                dotColor: theme.colorScheme.outlineVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: isLast
                    ? _finish
                    : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        ),
                child: Text(isLast ? 'Começar' : 'Seguinte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
