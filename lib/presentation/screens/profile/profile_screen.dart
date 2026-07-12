import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar sessão'),
        content: const Text('Tem a certeza de que quer sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        // Limpa os dados da conta anterior para não "vazarem" para a próxima.
        context.read<BusinessProvider>().reset();
        context.read<FavoritesProvider>().reset();
        context.read<NotificationProvider>().reset();
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Header ───────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: user.name,
                          imageUrl: user.avatarUrl,
                          radius: 34,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(user.roleLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  )),
                              if (user.email != null)
                                Text(user.email!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    )),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar perfil',
                          onPressed: () => Navigator.pushNamed(
                              context, AppRouter.editProfile),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Sections ─────────────────────────────
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Favoritos',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.favorites),
                  ),
                  _MenuItem(
                    icon: Icons.storefront_outlined,
                    label: 'Meu Negócio',
                    onTap: () => Navigator.pushNamed(
                        context, AppRouter.businessDashboard),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notificações',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.notifications),
                  ),
                ]),
                const SizedBox(height: 16),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Mudar palavra-passe',
                    onTap: () => Navigator.pushNamed(
                        context, AppRouter.changePassword),
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Definições',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.settings),
                  ),
                ]),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading:
                        Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                    title: Text('Terminar sessão',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        )),
                    onTap: () => _confirmLogout(context),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('AgroMoz v1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ),
              ],
            ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            ListTile(
              leading: Icon(items[i].icon),
              title: Text(items[i].label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: items[i].onTap,
            ),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}
