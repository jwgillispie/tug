import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:tug/blocs/activities/activities_bloc.dart';
import 'package:tug/blocs/theme/theme_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/config/env_confg.dart';
import 'package:tug/repositories/activity_repository.dart';
import 'package:tug/repositories/values_repository.dart';
import 'package:tug/screens/activity/activity_screen.dart';
import 'package:tug/screens/auth/forgot_password_screen.dart';
import 'package:tug/screens/diagnostics_screen.dart';
import 'package:tug/screens/help/help_screen.dart';
import 'package:tug/screens/home/home_screen.dart';
import 'package:tug/screens/legal/privacy_policy_screen.dart';
import 'package:tug/screens/legal/terms_screen.dart';
import 'package:tug/screens/main_layout.dart';
import 'package:tug/screens/profile/profile_screen.dart';
import 'package:tug/screens/progress/progress_screen.dart';
import 'package:tug/utils/local_storage.dart';
import 'package:tug/utils/render_utils.dart';
import 'repositories/auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'firebase_options.dart';
import 'utils/theme/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/values/values_input_screen.dart';

// Import new screens
import 'screens/about/about_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/change_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await EnvConfig.load();

    // Only initialize storage for non-web platforms
    if (!kIsWeb) {
      await LocalStorage.initialize();
    }

    // Initialize Firebase with the correct options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Ping the backend to wake it up if it's in cold start
    // This helps reduce latency for the first API call
    final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiUrl));
    try {
      debugPrint('Pinging backend at ${EnvConfig.apiUrl}');
      await RenderUtils.pingBackend(dio);
    } catch (e) {
      // Don't fail app startup if backend ping fails
      debugPrint('Backend ping failed: $e');
    }

    final authRepository = AuthRepository();
    final valuesRepository = ValuesRepository();
    final activityRepository = ActivityRepository();

    runApp(TugApp(
      authRepository: authRepository,
      valuesRepository: valuesRepository,
      activityRepository: activityRepository,
    ));
  } catch (e) {
    debugPrint('App initialization failed: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

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
                  onPressed: main,
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
  final AuthRepository authRepository;
  final ValuesRepository valuesRepository;
  final ActivityRepository activityRepository;

  const TugApp({
    required this.authRepository,
    required this.valuesRepository,
    required this.activityRepository,
    super.key,
  });

  @override
  State<TugApp> createState() => _TugAppState();
}

class _TugAppState extends State<TugApp> {
  late final GoRouter _router;
  late final AuthBloc _authBloc;
  late final ValuesBloc _valuesBloc;
  late final ActivitiesBloc _activitiesBloc;
  late final ThemeBloc _themeBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository);
    _valuesBloc = ValuesBloc(valuesRepository: widget.valuesRepository);
    _activitiesBloc =
        ActivitiesBloc(activityRepository: widget.activityRepository);
    _themeBloc = ThemeBloc();

    // Load theme preference
    _themeBloc.add(ThemeLoaded());

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(_authBloc.stream),
      routes: [
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        // New About Screen
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutScreen(),
        ),
        // New Help & Support Screen
        GoRoute(
          path: '/help',
          builder: (context, state) => const HelpSupportScreen(),
        ),
        // New Edit Profile Screen
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        // New Change Password Screen
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
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
        GoRoute(
          path: '/home',
          builder: (context, state) => const MainLayout(
            child: HomeScreen(),
            currentIndex: 0,
          ),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const MainLayout(
            child: ProgressScreen(),
            currentIndex: 1,
          ),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) => const MainLayout(
            child: ActivityScreen(),
            currentIndex: 2,
          ),
        ),
        GoRoute(
          path: '/activities/new',
          builder: (context, state) => const MainLayout(
            child: ActivityScreen(showAddForm: true),
            currentIndex: 2,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MainLayout(
            child: ProfileScreen(),
            currentIndex: 3,
          ),
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const DiagnosticScreen(),
        ),
      ],
      redirect: (context, state) {
        final currentState = _authBloc.state;
        final isLoggedIn = currentState is Authenticated;
        final isLoginScreen = state.fullPath == '/login';
        final isSignupScreen = state.fullPath == '/signup';
        final isDiagnosticScreen = state.fullPath == '/diagnostics';
        final isForgotPasswordScreen = state.fullPath == '/forgot-password';
        final isValuesInputScreen = state.fullPath == '/values-input';
        final isTermsScreen = state.fullPath == '/terms';
        final isPrivacyScreen = state.fullPath == '/privacy';

        if (isDiagnosticScreen) {
          return null;
        }

        if (isLoggedIn) {
          final hasCompletedOnboarding = true;

          if (!hasCompletedOnboarding) {
            return isValuesInputScreen ? null : '/values-input';
          } else {
            return isLoginScreen || isSignupScreen || isForgotPasswordScreen
                ? '/home'
                : null;
          }
        }

        if (!isLoggedIn &&
            !(isLoginScreen || isSignupScreen || isForgotPasswordScreen || 
              isTermsScreen || isPrivacyScreen)) {
          return '/login';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ValuesBloc>.value(value: _valuesBloc),
        BlocProvider<ActivitiesBloc>.value(value: _activitiesBloc),
        BlocProvider<ThemeBloc>.value(value: _themeBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Tug',
            theme: TugTheme.lightTheme,
            darkTheme: TugTheme.darkTheme,
            themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    _valuesBloc.close();
    _activitiesBloc.close();
    _themeBloc.close();
    super.dispose();
  }
}

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