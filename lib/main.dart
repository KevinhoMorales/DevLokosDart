import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/episode/episode_bloc_exports.dart';
import 'repository/episode_repository.dart';
import 'screens/home/home_screen.dart';
import 'screens/episode/episode_detail_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const DevLokosApp());
}

class DevLokosApp extends StatelessWidget {
  const DevLokosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EpisodeBloc>(
          create: (context) => EpisodeBloc(
            repository: EpisodeRepositoryImpl(),
          )..add(const LoadEpisodes()),
        ),
      ],
      child: MaterialApp.router(
        title: 'DevLokos Podcast',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/home',
  routes: [
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