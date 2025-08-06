import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/error_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/offline_error_service.dart';
import 'widgets/common/error_boundary.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/activities/activities_bloc.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/blocs/theme/theme_bloc.dart';
import 'package:tug/blocs/values/bloc/values_bloc.dart';
import 'package:tug/blocs/values/bloc/values_event.dart';
import 'package:tug/blocs/vices/bloc/vices_bloc.dart';
import 'package:tug/services/vice_service.dart';
import 'package:tug/services/mood_service.dart';
import 'package:tug/config/env_confg.dart';
import 'package:tug/repositories/activity_repository.dart';
import 'package:tug/repositories/values_repository.dart';
import 'package:tug/screens/activity/activity_screen.dart';
import 'package:tug/screens/auth/forgot_password_screen.dart';
import 'package:tug/screens/diagnostics_screen.dart';
import 'package:tug/screens/help/help_screen.dart';
import 'package:tug/screens/home/home_screen_refactored.dart';
import 'package:tug/screens/legal/privacy_policy_screen.dart';
import 'package:tug/screens/legal/terms_screen.dart';
import 'package:tug/screens/main_layout.dart';
import 'package:tug/screens/profile/profile_screen.dart';
import 'package:tug/screens/progress/progress_screen.dart';
import 'package:tug/screens/social/social_screen.dart';
import 'package:tug/screens/splash_screen.dart';
import 'package:tug/screens/subscription/subscription_screen.dart';
import 'package:tug/screens/subscription/user_subscription_screen.dart';
import 'package:tug/services/notification_service.dart';
import 'package:tug/services/subscription_service.dart';
import 'package:tug/services/service_locator.dart';
import 'package:tug/utils/local_storage.dart';
import 'repositories/auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'firebase_options.dart';
import 'utils/theme/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/values/values_input_screen.dart';
import 'screens/vices/vices_input_screen.dart';
import 'screens/vices/indulgence_screen.dart';
import 'screens/vices/vices_list_screen.dart';
import 'screens/vices/vices_calendar_screen.dart';
import 'screens/vices/indulgence_tracking_screen.dart';

// Import new screens
import 'screens/about/about_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/rankings/rankings_screen.dart';
import 'screens/user_profile/user_profile_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/notifications/notifications_screen.dart';

Future<void> main() async {
  // Initialize error handling zone first
  ErrorZone.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Initialize error services first
      await CrashReportingService().initialize();
      await OfflineErrorService().initialize();
      
      // IMPORTANT: Initialize environment config first to avoid the error
      await EnvConfig.load();

      // Initialize service locator early
      await ServiceLocator.initialize();

      // Initialize local storage next
      if (!kIsWeb) {
        await LocalStorage.initialize();
      }

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize notification service
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Create SubscriptionService without initializing (lazy initialization)
      final subscriptionService = SubscriptionService();

      final authRepository = AuthRepository();
      final valuesRepository = ValuesRepository();
      final activityRepository = ActivityRepository();

      runApp(ErrorBoundary(
        child: TugApp(
          authRepository: authRepository,
          valuesRepository: valuesRepository,
          activityRepository: activityRepository,
          subscriptionService: subscriptionService,
        ),
      ));
    } catch (e) {
      runApp(ErrorApp(error: e.toString()));
    }
  });
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({required this.error, super.key});

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
  final SubscriptionService subscriptionService;

  const TugApp({
    required this.authRepository,
    required this.valuesRepository,
    required this.activityRepository,
    required this.subscriptionService,
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
  late final SubscriptionBloc _subscriptionBloc;
  late final VicesBloc _vicesBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository);
    _valuesBloc = ValuesBloc(valuesRepository: widget.valuesRepository);
    _activitiesBloc = ActivitiesBloc(
      activityRepository: widget.activityRepository,
      moodService: MoodService(),
    );
    _themeBloc = ThemeBloc();
    _subscriptionBloc = SubscriptionBloc(
      subscriptionService: widget.subscriptionService,
    );
    _vicesBloc = VicesBloc(viceService: ViceService());

    // Load theme preference
    _themeBloc.add(ThemeLoaded());

    // Note: Subscription state will be loaded when user first visits subscription screen

    _router = GoRouter(
      initialLocation: '/splash', // Start at splash screen
      refreshListenable: GoRouterRefreshStream(_authBloc.stream),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
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
        // Rankings Screen
        GoRoute(
          path: '/rankings',
          builder: (context, state) => const RankingsScreen(),
        ),
        // Subscription Screen
        GoRoute(
          path: '/subscription',
          builder: (context, state) => const SubscriptionScreen(),
        ),
        // User Subscription Management Screen
        GoRoute(
          path: '/account',
          builder: (context, state) => const UserSubscriptionScreen(),
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
            currentIndex: 2,
            child: HomeScreenRefactored(),
          ),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const MainLayout(
            currentIndex: 1,
            child: ProgressScreen(),
          ),
        ),
        GoRoute(
          path: '/social',
          builder: (context, state) => const MainLayout(
            currentIndex: 0,
            child: SocialScreen(),
          ),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) => const ActivityScreen(),
        ),
        GoRoute(
          path: '/activities/new',
          builder: (context, state) => const MainLayout(
            currentIndex: 2,
            child: ActivityScreen(showAddForm: true),
          ),
        ),
        // Vices routes
        GoRoute(
          path: '/vices-input',
          builder: (context, state) => const VicesInputScreen(),
        ),
        GoRoute(
          path: '/indulgences',
          builder: (context, state) => const MainLayout(
            currentIndex: 2,
            child: IndulgenceScreen(),
          ),
        ),
        GoRoute(
          path: '/indulgences/new',
          builder: (context, state) => const MainLayout(
            currentIndex: 2,
            child: IndulgenceScreen(),
          ),
        ),
        // New vices screens
        GoRoute(
          path: '/vices-list',
          builder: (context, state) => const MainLayout(
            currentIndex: 1,
            child: VicesListScreen(),
          ),
        ),
        GoRoute(
          path: '/vices-calendar',
          builder: (context, state) => const MainLayout(
            currentIndex: 3,
            child: VicesCalendarScreen(),
          ),
        ),
        GoRoute(
          path: '/indulgence-tracking',
          builder: (context, state) => const MainLayout(
            currentIndex: 1,
            child: IndulgenceTrackingScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MainLayout(
            currentIndex: 3,
            child: ProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/user/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return UserProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const DiagnosticScreen(),
        ),
        // Notifications Screen
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const MainLayout(
            currentIndex: 3,
            child: NotificationsScreen(),
          ),
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
        final isOnboardingScreen = state.fullPath == '/onboarding';

        // Always allow access to diagnostic screen
        if (isDiagnosticScreen) {
          return null;
        }

        // Always allow access to splash screen and onboarding
        if (isSplashScreen || isOnboardingScreen) {
          return null;
        }

        // If user is logged in
        if (isLoggedIn) {
          // Allow onboarding for new users
          if (isOnboardingScreen) {
            return null;
          }

          // Allow values input screen for new users or from home
          if (isValuesInputScreen) {
            return null;
          }

          // Redirect from auth screens to social if already logged in
          if (isLoginScreen || isSignupScreen || isForgotPasswordScreen) {
            return '/social';
          }

          // Allow all other screens
          return null;
        }

        // If not logged in
        if (!isLoggedIn &&
            !(isLoginScreen ||
                isSignupScreen ||
                isForgotPasswordScreen ||
                isTermsScreen ||
                isPrivacyScreen ||
                isSplashScreen)) {
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
        BlocProvider<SubscriptionBloc>.value(value: _subscriptionBloc),
        BlocProvider<VicesBloc>.value(value: _vicesBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Clear all BLoC data when user becomes unauthenticated
          if (state is Unauthenticated) {
            context.read<ActivitiesBloc>().add(const ClearActivitiesData());
            context.read<ValuesBloc>().add(const ClearValuesData());
            context.read<SubscriptionBloc>().add(const LogoutSubscription());
          }
        },
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
      ),
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    _valuesBloc.close();
    _activitiesBloc.close();
    _themeBloc.close();
    _subscriptionBloc.close();
    _vicesBloc.close();
    widget.subscriptionService.dispose();
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
