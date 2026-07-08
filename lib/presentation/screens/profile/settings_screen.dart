import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Tema da aplicação',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeProvider.mode,
                  title: const Text('Automático (sistema)'),
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeProvider.mode,
                  title: const Text('Claro'),
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeProvider.mode,
                  title: const Text('Escuro'),
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Termos e condições'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Política de privacidade'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Versão'),
                  trailing: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
