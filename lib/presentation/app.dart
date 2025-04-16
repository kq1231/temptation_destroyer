import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temptation_destroyer/data/models/hobby_model.dart';
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
import 'providers/auth_provider.dart';
import '../domain/usecases/auth/get_user_status_usecase.dart';

/// Main app widget
class TemptationDestroyerApp extends ConsumerWidget {
  /// Constructor
  const TemptationDestroyerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
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

    // Initialize authentication state
    Future.microtask(() {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show loading indicator while initializing
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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

    // Placeholder while redirecting
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
