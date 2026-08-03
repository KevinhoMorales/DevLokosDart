import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'bloc/episode/episode_bloc_exports.dart';
import 'bloc/auth/auth_bloc_exports.dart';
import 'bloc/tutorial/tutorial_bloc_exports.dart';
import 'bloc/academy/academy_bloc_exports.dart';
import 'bloc/enterprise/enterprise_bloc_exports.dart';
import 'bloc/event/event_bloc_exports.dart';
import 'repository/episode_repository.dart';
import 'repository/academy_repository.dart';
import 'repository/enterprise_repository.dart';
import 'repository/tutorial_repository.dart';
import 'repository/event_repository.dart';
import 'providers/youtube_provider.dart';
import 'models/episode.dart';
import 'models/course.dart';
import 'models/youtube_video.dart';
import 'config/environment_config.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/episode_detail/episode_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/youtube/youtube_screen.dart';
import 'screens/events/events_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/academy/course_detail_screen.dart';
import 'widgets/main_navigation.dart';
import 'widgets/version_check_wrapper.dart';
import 'utils/brand_colors.dart';
import 'firebase_options.dart';
import 'services/remote_config_service.dart';
import 'services/analytics_service.dart';
import 'services/push_notification_service.dart'
    show PushNotificationService, firebaseMessagingBackgroundHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: BrandColors.primaryBlack,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: BrandColors.primaryBlack,
    ),
  );

  // Registrar handler de mensajes en background (debe ser antes de runApp)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Validar configuración del ambiente
  EnvironmentConfig.validateEnvironment();

  // Ejemplo: Verificar rutas para un usuario de prueba
  EnvironmentConfig.verifyUserPaths('test_user_123');

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Firebase Remote Config
  print('🔄 Inicializando Firebase Remote Config...');
  final remoteConfig = RemoteConfigService();
  await remoteConfig.initialize();

  // Verificar configuración
  print('🔍 Verificando configuración de Remote Config...');
  final isConfigured = remoteConfig.isRemoteConfigConfigured;
  print('✅ Remote Config configurado: $isConfigured');

  // Inicializar push notifications
  await PushNotificationService().initialize();

  // Habilitar colección de analítica (Firebase Analytics)
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // app_first_open solo en la primera ejecución post-instalación
  final prefs = await SharedPreferences.getInstance();
  final hasOpenedBefore = prefs.getBool('analytics_app_opened_before') ?? false;
  if (!hasOpenedBefore) {
    await AnalyticsService.logAppFirstOpen();
    await prefs.setBool('analytics_app_opened_before', true);
  }
  await AnalyticsService.logAppOpen();

  runApp(const DevLokosApp());
}

/// Configura la navegación al tocar notificaciones push (cursos, eventos).
class _PushNotificationRouterSetup extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const _PushNotificationRouterSetup({
    required this.router,
    required this.child,
  });

  @override
  State<_PushNotificationRouterSetup> createState() =>
      _PushNotificationRouterSetupState();
}

class _PushNotificationRouterSetupState
    extends State<_PushNotificationRouterSetup> {
  @override
  void initState() {
    super.initState();
    PushNotificationService.setNavigationHandler(
      (route) => widget.router.go(route),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class DevLokosApp extends StatelessWidget {
  const DevLokosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => YouTubeProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBlocSimple>(
            create: (context) => AuthBlocSimple()..add(const AuthCheckRequested()),
          ),
          BlocProvider<EpisodeBloc>(
            create: (context) => EpisodeBloc(
              repository: EpisodeRepositoryImpl(),
            )..add(const LoadEpisodes()),
          ),
          BlocProvider<TutorialBloc>(
            create: (context) => TutorialBloc(
              repository: TutorialRepositoryYouTube(
                youtubeProvider: context.read<YouTubeProvider>(),
              ),
            )..add(const LoadPlaylists()),
          ),
          BlocProvider<AcademyBloc>(
            create: (context) => AcademyBloc(
              repository: AcademyRepositoryImpl(),
            )..add(const LoadCourses()),
          ),
          BlocProvider<EnterpriseBloc>(
            create: (context) => EnterpriseBloc(
              repository: EnterpriseRepositoryImpl(),
            )..add(const LoadServices()),
          ),
          BlocProvider<EventBloc>(
            create: (context) => EventBloc(
              repository: EventRepository(),
            ),
          ),
        ],
        child: VersionCheckWrapper(
          child: _PushNotificationRouterSetup(
            router: _router,
            child: MaterialApp.router(
              title: 'DevLokos',
              theme: BrandColors.darkTheme,
              darkTheme: BrandColors.darkTheme,
              themeMode: ThemeMode.dark,
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
            ),
          ),
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  observers: [
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
  ],
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const SplashScreen(),
        state: state,
        transitionType: 'fade', // Splash usa fade
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const OnboardingScreen(),
        state: state,
        transitionType: 'fade',
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const LoginScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const RegisterScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const ForgotPasswordScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const MainNavigation(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/episode/:id',
      pageBuilder: (context, state) {
        final episodeId = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        return _buildPageWithTransition(
          child: EpisodeDetailScreen(
            episodeId: episodeId,
            episode: extra?['episode'] as Episode?,
            youtubeVideo: extra?['youtubeVideo'] as YouTubeVideo?,
            playlistTitle: extra?['playlistTitle'] as String?,
          ),
          state: state,
          transitionType: 'horizontal',
          maintainState: true,
        );
      },
    ),
    GoRoute(
      path: '/course/:id',
      pageBuilder: (context, state) {
        final courseId = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        final course = extra?['course'] as Course?;
        return _buildPageWithTransition(
          child: CourseDetailScreen(
            courseId: courseId,
            course: course,
          ),
          state: state,
          transitionType: 'horizontal',
          maintainState: true,
        );
      },
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const ProfileScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const SettingsScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/settings/about',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const AboutScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/youtube',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const YouTubeScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/events',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const EventsScreen(),
        state: state,
        transitionType: 'horizontal',
        maintainState: true,
      ),
    ),
    GoRoute(
      path: '/events/:id',
      pageBuilder: (context, state) {
        final eventId = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        return _buildPageWithTransition(
          child: EventDetailScreen(
            eventId: eventId,
            event: extra?['event'],
          ),
          state: state,
          transitionType: 'horizontal',
          maintainState: true,
        );
      },
    ),
  ],
);

// Función helper para crear páginas con transiciones personalizadas
CustomTransitionPage _buildPageWithTransition({
  required Widget child,
  required GoRouterState state,
  required String transitionType,
  bool maintainState = false,
}) {
  final screenName = state.matchedLocation;
  switch (transitionType) {
    case 'horizontal':
      return CustomTransitionPage(
        key: state.pageKey,
        name: screenName,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Animación horizontal suave estilo iOS
          // Nueva pantalla viene desde la derecha
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          // Para avanzar: nueva pantalla entra desde la derecha
          // Para retroceder: pantalla sale hacia la derecha
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        maintainState: maintainState,
      );
    case 'fade':
      return CustomTransitionPage(
        key: state.pageKey,
        name: screenName,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        maintainState: maintainState,
      );
    default:
      return CustomTransitionPage(
        key: state.pageKey,
        name: screenName,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
        maintainState: maintainState,
      );
  }
}

// Widget de página personalizada que extiende NoTransitionPage
class CustomTransitionPage extends Page<void> {
  final Widget child;
  final Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)? transitionsBuilder;
  final Duration transitionDuration;
  final Duration? reverseTransitionDuration;
  final bool maintainState;

  const CustomTransitionPage({
    required LocalKey key,
    String? name,
    required this.child,
    this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration,
    this.maintainState = false,
  }) : super(key: key, name: name);

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      opaque: true,
      barrierColor: BrandColors.primaryBlack,
      pageBuilder: (context, animation, secondaryAnimation) =>
          ColoredBox(color: BrandColors.primaryBlack, child: child),
      transitionsBuilder: transitionsBuilder ??
          (context, animation, secondaryAnimation, child) => child,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration ?? transitionDuration,
      maintainState: maintainState,
    );
  }
}