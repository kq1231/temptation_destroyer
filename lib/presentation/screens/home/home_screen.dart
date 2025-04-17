import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/emergency/floating_help_button.dart';
import '../triggers/trigger_collection_screen.dart';

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
                // Navigate to the TriggerCollectionScreen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TriggerCollectionScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('Activities'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/hobbies');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Aspirations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/aspirations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('AI Guidance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/ai-guidance');
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/statistics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Recovery Codes'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).pushNamed('/recovery-codes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text('AI Service Setup'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.of(context).pushNamed('/api-key-setup');
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 32),

          // Feature navigation cards
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureButton(
                        context,
                        Icons.flash_on,
                        'Triggers',
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const TriggerCollectionScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureButton(
                        context,
                        Icons.sports,
                        'Hobbies',
                        () => Navigator.of(context).pushNamed('/hobbies'),
                      ),
                      _buildFeatureButton(
                        context,
                        Icons.star,
                        'Goals',
                        () => Navigator.of(context).pushNamed('/aspirations'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureButton(
                        context,
                        Icons.chat_bubble_outline,
                        'AI Help',
                        () => Navigator.of(context).pushNamed('/ai-guidance'),
                      ),
                      _buildFeatureButton(
                        context,
                        Icons.insights,
                        'Stats',
                        () => Navigator.of(context).pushNamed('/statistics'),
                      ),
                      const SizedBox(width: 80), // Empty space for balance
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
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

  /// Build a feature navigation button
  Widget _buildFeatureButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
