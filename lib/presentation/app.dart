import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
import 'package:temptation_destroyer/data/models/chat_session_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/password_setup_screen.dart';
import 'screens/auth/recovery_codes_screen.dart';
import 'screens/auth/password_recovery_screen.dart';
import 'screens/auth/api_key/api_key_setup_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/hobbies/hobby_management_screen.dart';
import 'screens/hobbies/hobby_form_screen.dart';
import 'screens/hobbies/hobby_details_screen.dart';
import 'screens/aspirations/aspirations_management_screen.dart';
import 'screens/ai/ai_guidance_screen.dart';
import 'screens/ai/chat_sessions_screen.dart';
import 'screens/ai/ai_settings_screen.dart';
import 'screens/statistics/statistics_dashboard_screen.dart';
import 'screens/voice/voice_chat_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/app_start_provider.dart';
import '../domain/usecases/auth/get_user_status_usecase.dart';
import '../core/services/notification_service.dart';

/// Main app widget
class TemptationDestroyerApp extends ConsumerWidget {
  /// Constructor
  const TemptationDestroyerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the notification service
    final notificationService = ref.watch(notificationServiceProvider);

    return MaterialApp(
      navigatorKey: notificationService.navigatorKey,
      title: 'Temptation Destroyer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthCheckScreen(),
        '/login': (context) => const LoginScreen(),
        '/password-setup': (context) => const PasswordSetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/recovery-codes': (context) => const RecoveryCodesScreen(),
        '/recovery': (context) => const PasswordRecoveryScreen(),
        '/api-key-setup': (context) => const ApiKeySetupScreen(),
        '/hobbies': (context) => const HobbyManagementScreen(),
        '/hobbies/add': (context) => const HobbyFormScreen(),
        '/aspirations': (context) => const AspirationsManagementScreen(),
        '/chat-sessions': (context) => const ChatSessionsScreen(),
        '/statistics': (context) => const StatisticsDashboardScreen(),
        '/ai-settings': (context) => const AISettingsScreen(),
        '/voice-chat': (context) => const VoiceChatScreen(),
      },
      // Add onGenerateRoute for dynamic routes
      onGenerateRoute: (settings) {
        if (settings.name == '/hobbies/edit') {
          // Extract the hobby from arguments
          final hobby = settings.arguments as HobbyModel?;
          return MaterialPageRoute(
            builder: (context) => HobbyFormScreen(hobby: hobby),
          );
        } else if (settings.name == '/hobbies/details') {
          // Extract the hobby from arguments
          final hobby = settings.arguments as HobbyModel;
          return MaterialPageRoute(
            builder: (context) => HobbyDetailsScreen(hobby: hobby),
          );
        } else if (settings.name == '/ai-guidance') {
          // Handle both ChatSession and Map arguments
          if (settings.arguments is ChatSession) {
            final session = settings.arguments as ChatSession;
            return MaterialPageRoute(
              builder: (context) => AIGuidanceScreen(session: session),
            );
          } else if (settings.arguments is Map<String, dynamic>) {
            // Pass the map directly to the screen
            return MaterialPageRoute(
              builder: (context) => const AIGuidanceScreen(session: null),
            );
          } else {
            // Default case with no session
            return MaterialPageRoute(
              builder: (context) => const AIGuidanceScreen(session: null),
            );
          }
        }
        return null;
      },
    );
  }
}

/// Screen that checks the authentication status and redirects accordingly
class AuthCheckScreen extends ConsumerStatefulWidget {
  /// Constructor
  const AuthCheckScreen({super.key});

  @override
  ConsumerState<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize app and authentication state
    Future.microtask(() {
      // Initialize app start provider (which checks for active emergency sessions)
      ref.read(appStartProvider);

      // Initialize authentication state
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Use our new splash screen while initializing
    if (authState.isLoading) {
      return const SplashScreen();
    }

    // Redirect based on auth status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.status == AuthStatus.newUser) {
        Navigator.of(context).pushReplacementNamed('/password-setup');
      } else if (authState.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    // Placeholder while redirecting - use splash screen here too
    return const SplashScreen();
  }
}
