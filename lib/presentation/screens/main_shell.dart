import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/business_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_router.dart';
import '../widgets/offline_banner.dart';
import 'articles/articles_screen.dart';
import 'home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'profile/profile_screen.dart';
import 'suppliers/suppliers_screen.dart';

/// Navegação principal: Início · Marketplace · Fornecedores · Aprender · Perfil.
///
/// Cada aba tem o SEU PRÓPRIO Navigator (nested navigators), por isso quando
/// se abre uma página como "Meu Negócio" ou o detalhe de um produto, ela
/// abre DENTRO da aba e o menu inferior permanece SEMPRE visível. O botão
/// físico de "voltar" recua primeiro dentro da aba ativa.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Uma GlobalKey de Navigator por aba, para gerir a pilha de cada uma.
  final List<GlobalKey<NavigatorState>> _navKeys =
      List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const _roots = [
    HomeScreen(),
    MarketplaceScreen(),
    SuppliersScreen(),
    ArticlesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
      context.read<BusinessProvider>().load();
    });
  }

  void _onSelect(int i) {
    if (i == _index) {
      // Tocar na aba já ativa volta à raiz dessa aba.
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  /// Navigator dedicado a uma aba. A página raiz é [root]; tudo o que for
  /// aberto com Navigator.pushNamed dentro da aba usa o mesmo onGenerateRoute.
  Widget _tabNavigator(int i, Widget root) {
    return Navigator(
      key: _navKeys[i],
      onGenerateRoute: (settings) {
        if (settings.name == null || settings.name == '/') {
          return MaterialPageRoute(builder: (_) => root, settings: settings);
        }
        return AppRouter.onGenerateRoute(settings);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop(); // recua dentro da aba
        } else if (_index != 0) {
          setState(() => _index = 0); // volta ao Início
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (int i = 0; i < _roots.length; i++)
                    _tabNavigator(i, _roots[i]),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onSelect,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Marketplace',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Fornecedores',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Aprender',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
