import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/emergency/floating_help_button.dart';

/// Main home screen of the app
class HomeScreen extends ConsumerWidget {
  /// Constructor
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
              // Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  if (user != null)
                    Text(
                      'Last login: ${user.lastLoginDate?.toString().split(' ')[0] ?? 'Never'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Triggers'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.of(context).pushNamed('/triggers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('Activities'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.of(context).pushNamed('/activities');
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                // Navigator.of(context).pushNamed('/statistics');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
      body: _buildHomeContent(context),
      floatingActionButton: const FloatingHelpButton(),
    );
  }

  /// Build the home screen content
  Widget _buildHomeContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for dashboard content
          const Icon(
            Icons.shield_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to Temptation Destroyer',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your ally in overcoming temptation',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'If you need emergency help, press the button below',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const Icon(
            Icons.arrow_downward,
            size: 40,
            color: AppColors.emergencyRed,
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog before logout
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                // Log out and return to login screen
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
