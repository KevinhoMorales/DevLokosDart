import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../bloc/episode/episode_bloc_exports.dart';
import '../../bloc/auth/auth_bloc_exports.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../providers/youtube_provider.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/episode_card.dart';
import '../../widgets/featured_episode_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEpisodes();
    });
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final state = context.read<EpisodeBloc>().state;
      if (state is EpisodeLoaded) {
        if (state.searchQuery.isNotEmpty && state.hasMoreSearchResults) {
          _isLoadingMore = true;
          context.read<EpisodeBloc>().add(
            LoadMoreSearchResults(query: state.searchQuery),
          );
        } else if (state.searchQuery.isEmpty) {
          _isLoadingMore = true;
          context.read<EpisodeBloc>().add(const LoadMoreEpisodes());
        }
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _loadEpisodes() {
    context.read<EpisodeBloc>().add(const RefreshEpisodes());
  }

  void _clearCacheAndReload() {
    context.read<EpisodeBloc>().add(const ClearCacheAndReload());
  }

  void _navigateToEpisodeDetail(Episode episode) {
    // Buscar el video de YouTube correspondiente
    final youtubeProvider = context.read<YouTubeProvider>();
    YouTubeVideo? correspondingVideo;
    
    try {
      correspondingVideo = youtubeProvider.videos.firstWhere(
        (video) => video.videoId == episode.youtubeVideoId,
      );
    } catch (e) {
      correspondingVideo = null;
    }

    // Navegar a la pantalla de detalle con los datos usando push para mantener el historial
    context.push('/episode/${episode.id}', 
      extra: {
        'episode': episode,
        'youtubeVideo': correspondingVideo,
      }
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EpisodeBloc, EpisodeState>(
      listener: (context, state) {
        if (state is EpisodeLoaded) _isLoadingMore = false;
      },
      child: BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Forzar actualización de la UI cuando el usuario se autentique
          setState(() {
            // Esto forzará la reconstrucción del widget
          });
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          // Si el usuario presiona el botón back, mostrar diálogo de confirmación
          if (!didPop) {
            final shouldPop = await _showExitDialog();
            if (shouldPop && context.mounted) {
              // Si el usuario confirma, salir de la app
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(
            title: '',
            actions: [
              IconButton(
                onPressed: _clearCacheAndReload,
                icon: const Icon(
                  Icons.refresh,
                  color: BrandColors.primaryOrange,
                ),
                tooltip: 'Limpiar caché y recargar',
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              color: BrandColors.primaryBlack,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de la aplicación'),
        content: const Text('¿Estás seguro de que quieres salir de DevLokos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: SearchBarWidget(
        controller: _searchController,
        onChanged: (value) {
          // Disparar búsqueda con BLoC
          if (value.isNotEmpty) {
            context.read<EpisodeBloc>().add(SearchEpisodes(query: value));
          } else {
            context.read<EpisodeBloc>().add(const ClearSearch());
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<EpisodeBloc, EpisodeState>(
      builder: (context, state) {
        if (state is EpisodeLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
            ),
          );
        }

        if (state is EpisodeError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: BrandColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar episodios',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BrandColors.primaryWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.grayMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadEpisodes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.primaryOrange,
                    foregroundColor: BrandColors.primaryWhite,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is EpisodeLoaded || state is EpisodeSearching) {
          final episodes = state is EpisodeLoaded ? state.episodes : (state as EpisodeSearching).episodes;
          final featuredEpisodes = state is EpisodeLoaded ? state.featuredEpisodes : [];
          final searchQuery = state is EpisodeLoaded ? state.searchQuery : 
                            state is EpisodeSearching ? state.query : '';

          if (episodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: BrandColors.grayMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isEmpty
                        ? 'No hay episodios disponibles'
                        : 'No se encontraron episodios',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BrandColors.primaryWhite,
                    ),
                  ),
                  if (searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Intenta con otros términos de búsqueda',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BrandColors.grayMedium,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (searchQuery.isEmpty) ...[
                  _buildDiscoverSection(featuredEpisodes.cast<Episode>()),
                  const SizedBox(height: 20),
                ],
                _buildEpisodesSection(episodes, searchQuery),
              ],
            ),
          );
        }

        // Estado inicial - mostrar loading
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
          ),
        );
      },
    );
  }

  /// Sección "Descubre": horizontal scroll compacto, hero visual
  Widget _buildDiscoverSection(List<Episode> featuredEpisodes) {
    if (featuredEpisodes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descubre',
          style: TextStyle(
            color: BrandColors.primaryOrange,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featuredEpisodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final episode = featuredEpisodes[index];
              return FeaturedEpisodeCard(
                episode: episode,
                onTap: () => _navigateToEpisodeDetail(episode),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Listado de episodios: densidad media, jerarquía secundaria
  Widget _buildEpisodesSection(List<Episode> episodes, String searchQuery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 1,
              width: 20,
              color: BrandColors.primaryOrange.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Text(
              searchQuery.isEmpty ? 'Episodios' : 'Búsqueda',
              style: TextStyle(
                color: BrandColors.grayMedium,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return EpisodeCard(
              episode: episode,
              onTap: () => _navigateToEpisodeDetail(episode),
            );
          },
        ),
      ],
    );
  }
}