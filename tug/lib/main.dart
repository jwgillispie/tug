import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
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
import 'package:tug/screens/splash_screen.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/services/cache_service.dart';
import 'package:tug/utils/local_storage.dart';
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
import 'screens/achievements/achievements_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // IMPORTANT: Initialize environment config first to avoid the error
    await EnvConfig.load();
    
    // Initialize cache service before repositories
    final cacheService = CacheService();
    await cacheService.initialize();
    debugPrint('Cache service initialized');
    
    // Initialize local storage next
    if (!kIsWeb) {
      await LocalStorage.initialize();
    }
    
    // Initialize Firebase last
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final apiService = ApiService();
    final authRepository = AuthRepository();
    final valuesRepository = ValuesRepository(apiService: apiService, cacheService: cacheService);
    final activityRepository = ActivityRepository(apiService: apiService, cacheService: cacheService);

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
      initialLocation: '/splash',  // Start at splash screen
      refreshListenable: GoRouterRefreshStream(_authBloc.stream),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
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
        // Achievements Screen
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementsScreen(),
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
          builder: (context, state) {
            // Check if coming from home screen for edit mode
            final fromHome = state.uri.queryParameters['fromHome'] == 'true';
            return ValuesInputScreen(fromHome: fromHome);
          },
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
            currentIndex: 4,
          ),
        ),
        GoRoute(
          path: '/achievements-tab',
          builder: (context, state) => const MainLayout(
            child: AchievementsScreen(),
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
        final isSplashScreen = state.fullPath == '/splash';
        final isLoginScreen = state.fullPath == '/login';
        final isSignupScreen = state.fullPath == '/signup';
        final isDiagnosticScreen = state.fullPath == '/diagnostics';
        final isForgotPasswordScreen = state.fullPath == '/forgot-password';
        final isValuesInputScreen = state.fullPath == '/values-input';
        final isTermsScreen = state.fullPath == '/terms';
        final isPrivacyScreen = state.fullPath == '/privacy';

        // Always allow access to diagnostic screen
        if (isDiagnosticScreen) {
          return null;
        }

        // Always allow access to splash screen
        if (isSplashScreen) {
          return null;
        }

        // If user is logged in
        if (isLoggedIn) {
          // If coming from home to values input, allow it
          if (isValuesInputScreen && state.uri.queryParameters['fromHome'] == 'true') {
            return null;
          }

          // Redirect from auth screens to home if already logged in
          if (isLoginScreen || isSignupScreen || isForgotPasswordScreen) {
            return '/home';
          }

          // Allow all other screens
          return null;
        }

        // If not logged in
        if (!isLoggedIn && 
            !(isLoginScreen || isSignupScreen || isForgotPasswordScreen || 
              isTermsScreen || isPrivacyScreen || isSplashScreen)) {
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