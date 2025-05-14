// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Display',
            children: [
              Consumer<ThemeController>(
                builder: (context, themeController, child) {
                  return SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: themeController.isDarkMode,
                    onChanged: (value) {
                      themeController.toggleTheme();
                    },
                  );
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Map Settings',
            children: [
              ListTile(
                title: const Text('Map Type'),
                subtitle: const Text('Normal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement map type selection
                },
              ),
              SwitchListTile(
                title: const Text('Traffic Layer'),
                subtitle: const Text('Show real-time traffic'),
                value: false,
                onChanged: (value) {
                  // TODO: Implement traffic layer toggle
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Route Preferences',
            children: [
              ListTile(
                title: const Text('Avoid Highways'),
                subtitle: const Text('Route around highways when possible'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement avoid highways
                  },
                ),
              ),
              ListTile(
                title: const Text('Avoid Tolls'),
                subtitle: const Text('Route around toll roads'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement avoid tolls
                  },
                ),
              ),
            ],
          ),
          _buildSection(
            title: 'About',
            children: [
              const ListTile(
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show terms of service
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show privacy policy
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
