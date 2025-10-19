import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bloc/episode/episode_bloc_exports.dart';
import 'bloc/auth/auth_bloc_exports.dart';
import 'repository/episode_repository.dart';
import 'providers/youtube_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/episode/episode_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/youtube/youtube_screen.dart';
import 'widgets/main_navigation.dart';
import 'widgets/version_check_wrapper.dart';
import 'utils/brand_colors.dart';
import 'firebase_options.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(const DevLokosApp());
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
        ],
        child: VersionCheckWrapper(
          child: MaterialApp.router(
            title: 'DevLokos',
            theme: BrandColors.lightTheme,
            darkTheme: BrandColors.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
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
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigation(),
    ),
    GoRoute(
      path: '/episode/:id',
      builder: (context, state) {
        final episodeId = state.pathParameters['id']!;
        return EpisodeDetailScreen(episodeId: episodeId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/youtube',
      builder: (context, state) => const YouTubeScreen(),
    ),
  ],
);