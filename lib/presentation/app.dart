import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/password_setup_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/auth_provider.dart';
import '../domain/usecases/auth/get_user_status_usecase.dart';

/// Main app widget
class TemptationDestroyerApp extends ConsumerStatefulWidget {
  /// Constructor
  const TemptationDestroyerApp({super.key});

  @override
  ConsumerState<TemptationDestroyerApp> createState() =>
      _TemptationDestroyerAppState();
}

class _TemptationDestroyerAppState
    extends ConsumerState<TemptationDestroyerApp> {
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
    return MaterialApp(
      title: 'Temptation Destroyer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/password-setup': (context) => const PasswordSetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/emergency': (context) => const EmergencyScreen(),
      },
    );
  }
}

/// Screen that checks the authentication status and redirects accordingly
class AuthCheckScreen extends ConsumerWidget {
  /// Constructor
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      } else if (authState.status == AuthStatus.existingUser) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else if (authState.status == AuthStatus.authenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Error state, show login screen
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
