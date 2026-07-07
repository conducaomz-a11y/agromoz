import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import 'home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'messages/conversations_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

/// Bottom navigation shell: Home · Marketplace · Search · Messages · Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    MarketplaceScreen(),
    SearchScreen(),
    ConversationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadChats = context.select<ChatProvider, int>(
      (p) => p.conversations.fold(0, (sum, c) => sum + c.unreadCount),
    );

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Mercado',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.saved_search_rounded),
            label: 'Pesquisar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: 'Mensagens',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
