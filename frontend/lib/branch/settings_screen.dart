import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsSection(
            title: 'Account',
            children: [
              _buildSettingsTile(
                icon: Icons.person,
                title: 'Profile',
                onTap: () {
                  // Handle Profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile clicked'),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.lock,
                title: 'Change Password',
                onTap: () {
                  // Handle Change Password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Change Password clicked'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: 'Preferences',
            children: [
              _buildSettingsTile(
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                  // Handle Notifications
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications clicked'),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.language,
                title: 'Language',
                onTap: () {
                  // Handle Language
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language clicked'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: 'Actions',
            children: [
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () {
                  // Handle Logout
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}