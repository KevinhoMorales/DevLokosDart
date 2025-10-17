import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bloc/episode/episode_bloc_exports.dart';
import 'bloc/auth/auth_bloc_exports.dart';
import 'repository/episode_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/episode/episode_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'utils/brand_colors.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DevLokosApp());
}

class DevLokosApp extends StatelessWidget {
  const DevLokosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
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
      child: MaterialApp.router(
        title: 'DevLokos',
        theme: BrandColors.lightTheme,
        darkTheme: BrandColors.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
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
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/episode/:id',
      builder: (context, state) {
        final episodeId = state.pathParameters['id']!;
        return EpisodeDetailScreen(episodeId: episodeId);
      },
    ),
  ],
);