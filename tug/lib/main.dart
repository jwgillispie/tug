// lib/main.dart
// Key changes to initialization sequence

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/config/env_confg.dart';
import 'package:tug/screens/auth/forgot_password_screen.dart';
import 'package:tug/screens/diagnostics_screen.dart';
import 'repositories/auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'firebase_options.dart';
import 'utils/theme/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/values/values_input_screen.dart';
import 'screens/splash_screen.dart';

// IMPORTANT: Simplified initialization with proper error trapping
Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();

  try {
    // Initialize Firebase with explicit options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase initialized successfully');

    // Create repository instance AFTER Firebase is ready
    final authRepository = AuthRepository();

    runApp(TugApp(authRepository: authRepository));
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Show error UI
    runApp(ErrorApp(error: e.toString()));
  }
}

// Error fallback app
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({required this.error, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TugApp extends StatefulWidget {
  final IAuthRepository authRepository;

  const TugApp({
    required this.authRepository,
    super.key,
  });

  @override
  State<TugApp> createState() => _TugAppState();
}

class _TugAppState extends State<TugApp> {
  late final GoRouter _router;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository);

    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(_authBloc.stream),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/values-input',
          builder: (context, state) => const ValuesInputScreen(),
        ),
        // Add the diagnostic route
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const DiagnosticScreen(),
        ),
        // Add more routes here
      ],
      redirect: (context, state) {
        final currentState = _authBloc.state;
        final isLoggedIn = currentState is Authenticated;
        final isSplashScreen = state.fullPath == '/splash';
        final isLoginScreen = state.fullPath == '/login';
        final isSignupScreen = state.fullPath == '/signup';
        final isDiagnosticScreen = state.fullPath == '/diagnostics';

        // Always allow access to diagnostic screen
        if (isDiagnosticScreen) {
          return null;
        }

        // Allow access to splash screen for initial loading
        if (isSplashScreen) {
          return null;
        }

        // If not authenticated, redirect to login unless already on login or signup
        if (!isLoggedIn && !(isLoginScreen || isSignupScreen)) {
          return '/login';
        }

        // If authenticated, don't allow going to login/signup screens
        print("Here we can see if the user is logged in: $isLoggedIn");
        print("the current state is: $currentState");
        if (isLoggedIn && (isLoginScreen || isSignupScreen)) {
          return '/values-input'; // Redirect to values input screen
        }

        return null; // Allow the navigation to proceed
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
      ],
      child: MaterialApp.router(
        title: 'Tug', // Changed from 'tug' to 'Tug'
        theme: TugTheme.lightTheme,
        darkTheme: TugTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }
}

// Helper class to refresh GoRouter based on BLoC stream
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
