import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/episode/episode_bloc_exports.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../providers/youtube_provider.dart';
import '../../constants/podcast_seasons.dart';
import '../../utils/brand_colors.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/season_filter_dropdown.dart';
import '../../widgets/youtube_video_card.dart';

class PodcastScreen extends StatefulWidget {
  const PodcastScreen({super.key});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  List<YouTubeVideo>? _apiSearchResults;
  String? _searchError;
  String _selectedSeason = PodcastSeasons.defaultLabel;
  List<YouTubeVideo>? _discoverVideos; // Cache estable para Descubre
  List<YouTubeVideo>? _allVideosSorted; // Cache para todos los videos ordenados por fecha
  List<YouTubeVideo>? _s1VideosSorted;
  List<YouTubeVideo>? _s2VideosSorted;
  List<YouTubeVideo>? _s3VideosSorted;
  bool _isInitialLoading = true; // Estado de carga inicial
  String _loadingMessage = 'Cargando videos...'; // Mensaje de loading
  bool _hasLoaded = false; // Flag para asegurar que solo se carga una vez
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _discoverScrollController = ScrollController();
  Timer? _discoverAutoScrollTimer;
  Timer? _discoverResumeTimer;
  Timer? _searchDebounce;
  bool _discoverUserInteracting = false;
  bool _isLoadingMoreEpisodes = false;
  static const int _discoverCount = 10;
  static const double _paginationThreshold = 480;
  /// Continuous rail drift (~28 px/s).
  static const Duration _discoverTickInterval = Duration(milliseconds: 16);
  static const double _discoverPixelsPerTick = 0.45;

  @override
  bool get wantKeepAlive => true; // Mantener el estado vivo cuando se navega

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollListener();
    // Cargar episodios y videos de YouTube después de que el widget esté montado
    // Solo cargar si no se ha cargado antes
    if (!_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEpisodes();
        _loadYouTubeVideos();
        _hasLoaded = true;
      });
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

  void _loadYouTubeVideos() async {
    final youtubeProvider = context.read<YouTubeProvider>();

    if (mounted) {
      setState(() => _loadingMessage = 'CARGANDO EPISODIOS');
    }

    // 1) Caché / API: pintar lo antes posible
    if (youtubeProvider.videos.isEmpty) {
      await youtubeProvider.loadVideos(initialLoad: true, maxResults: 30);
    }

    // Si la caché vino vacía o falló, forzar red
    if (youtubeProvider.videos.isEmpty) {
      await youtubeProvider.loadVideos(
        refresh: true,
        initialLoad: true,
        maxResults: 30,
      );
    }

    _generateDiscoverVideos(youtubeProvider.videos);
    _generateSortedVideos(youtubeProvider.videos);

    if (mounted) {
      setState(() => _isInitialLoading = false);
    }

    // 2) Prefetch transparente en background (sin reshuffle de Descubre)
    _loadMoreVideosInBackground(youtubeProvider);
  }

  /// Prefetch en segundo plano; actualiza Episodios sin tocar Descubre.
  Future<void> _loadMoreVideosInBackground(YouTubeProvider provider) async {
    int loadedBatches = 0;
    const maxInitialBatches = 4;

    while (loadedBatches < maxInitialBatches &&
        provider.hasMoreVideos &&
        mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) break;

      await provider.loadMoreVideos(batchSize: 30);
      loadedBatches++;

      if (!mounted) break;
      setState(() {
        _generateSortedVideos(provider.videos);
        // Completar Descubre hasta el cupo sin reordenar lo ya visible
        _generateDiscoverVideos(provider.videos);
      });
    }

    // Si la temporada activa sigue corta, seguir paginando un poco más
    await _ensureSeasonHasContent();
  }

  /// Descubre: episodios recientes (no aleatorios) para encontrar lo nuevo rápido.
  void _generateDiscoverVideos(List<YouTubeVideo> allVideos) {
    if (allVideos.isEmpty) return;

    final validVideos = allVideos
        .where((video) =>
            video.title.isNotEmpty &&
            video.title.trim().isNotEmpty &&
            video.title != 'Sin título')
        .toList();
    if (validVideos.isEmpty) return;

    // Ordenar por fecha descendente; rellenar Descubre sin reordenar lo ya visible
    final byDate = List<YouTubeVideo>.from(validVideos)
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    if (_discoverVideos != null && _discoverVideos!.isNotEmpty) {
      if (_discoverVideos!.length >= _discoverCount) {
        _scheduleDiscoverAutoScroll();
        return;
      }
      final existingIds = _discoverVideos!.map((v) => v.videoId).toSet();
      final extras = byDate
          .where((v) => !existingIds.contains(v.videoId))
          .take(_discoverCount - _discoverVideos!.length);
      _discoverVideos = [..._discoverVideos!, ...extras];
      _scheduleDiscoverAutoScroll();
      return;
    }

    _discoverVideos = byDate.take(_discoverCount).toList();
    _scheduleDiscoverAutoScroll();
  }

  void _scheduleDiscoverAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final count = _discoverVideos?.length ?? 0;
      if (count <= 1) return;
      if (_discoverAutoScrollTimer == null ||
          !_discoverAutoScrollTimer!.isActive) {
        _startDiscoverAutoScroll();
      }
    });
  }

  void _generateSortedVideos(List<YouTubeVideo> allVideos) {
    if (allVideos.isNotEmpty) {
      // Eliminar duplicados basándose en el videoId
      final uniqueVideos = <String, YouTubeVideo>{};
      for (final video in allVideos) {
        uniqueVideos[video.videoId] = video;
      }
      final deduplicatedVideos = uniqueVideos.values.toList();
      
      // Separar por temporada (S3 / S2 / S1); extensible vía PodcastSeasons
      final s1Videos = deduplicatedVideos
          .where((v) => PodcastSeasons.detectFromTitle(v.title) == 1)
          .toList();
      final s2Videos = deduplicatedVideos
          .where((v) => PodcastSeasons.detectFromTitle(v.title) == 2)
          .toList();
      final s3Videos = deduplicatedVideos
          .where((v) => PodcastSeasons.detectFromTitle(v.title) == 3)
          .toList();

      s1Videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      s2Videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      s3Videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      // Orden global: S3 → S2 → S1 (más reciente primero dentro de cada una)
      _allVideosSorted = [...s3Videos, ...s2Videos, ...s1Videos];
      _s1VideosSorted = s1Videos;
      _s2VideosSorted = s2Videos;
      _s3VideosSorted = s3Videos;

      print('📅 Videos ordenados: T3=${s3Videos.length} T2=${s2Videos.length} T1=${s1Videos.length}');
    }
  }

  void _setupScrollListener() {
    _mainScrollController.addListener(() {
      if (!_mainScrollController.hasClients) return;
      final position = _mainScrollController.position;
      if (position.maxScrollExtent <= 0) return;
      if (position.pixels >= position.maxScrollExtent - _paginationThreshold) {
        _maybeLoadMoreEpisodes();
      }
    });
  }

  /// Paginado automático transparente al acercarse al final del scroll.
  Future<void> _maybeLoadMoreEpisodes() async {
    if (_isLoadingMoreEpisodes || !mounted) return;
    final provider = context.read<YouTubeProvider>();
    if (!provider.hasMoreVideos || provider.isLoading) return;

    setState(() => _isLoadingMoreEpisodes = true);
    try {
      await provider.loadMoreVideos(batchSize: 30);
      if (!mounted) return;
      setState(() {
        _generateSortedVideos(provider.videos);
        _generateDiscoverVideos(provider.videos);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMoreEpisodes = false);
      } else {
        _isLoadingMoreEpisodes = false;
      }
    }
  }

  Future<void> _ensureSeasonHasContent() async {
    if (!mounted) return;
    final provider = context.read<YouTubeProvider>();
    var safety = 0;
    while (
      mounted &&
      provider.hasMoreVideos &&
      !provider.isLoading &&
      _filterVideosBySeason(provider.videos).length < 12 &&
      safety < 6
    ) {
      safety++;
      await provider.loadMoreVideos(batchSize: 30);
      if (!mounted) return;
      setState(() {
        _generateSortedVideos(provider.videos);
        _generateDiscoverVideos(provider.videos);
      });
    }
  }

  void _startDiscoverAutoScroll() {
    _discoverAutoScrollTimer?.cancel();
    final count = _discoverVideos?.length ?? 0;
    if (count <= 1) return;
    _discoverAutoScrollTimer = Timer.periodic(_discoverTickInterval, (_) {
      _tickDiscoverRail();
    });
  }

  void _stopDiscoverAutoScroll() {
    _discoverAutoScrollTimer?.cancel();
    _discoverAutoScrollTimer = null;
    _discoverResumeTimer?.cancel();
    _discoverResumeTimer = null;
  }

  void _pauseDiscoverAutoScrollTemporarily() {
    _discoverUserInteracting = true;
    _discoverResumeTimer?.cancel();
    _discoverResumeTimer = Timer(const Duration(seconds: 2), () {
      _discoverUserInteracting = false;
    });
  }

  void _tickDiscoverRail() {
    if (!mounted || _discoverUserInteracting) return;
    if (!_discoverScrollController.hasClients) return;
    final position = _discoverScrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) return;

    final next = position.pixels + _discoverPixelsPerTick;
    if (next >= position.maxScrollExtent - 0.5) {
      _discoverScrollController.jumpTo(0);
    } else {
      _discoverScrollController.jumpTo(next);
    }
  }

  @override
  void dispose() {
    _stopDiscoverAutoScroll();
    _searchDebounce?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    _mainScrollController.dispose();
    _discoverScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _showExitDialog();
          if (shouldPop && context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(title: ''),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BrandColors.primaryBlack,
                BrandColors.primaryBlack,
                BrandColors.blackDark.withOpacity(0.95),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
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
      ),
    );
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
      padding: Responsive.searchBarPadding(context),
      child: SearchBarWidget(
        controller: _searchController,
        hintText: 'Buscar episodios, invitado o tema...',
        onChanged: (value) {
          final query = value.trim();
          setState(() {
            _searchQuery = query;
            if (query.isEmpty) {
              _apiSearchResults = null;
              _searchError = null;
              _isSearching = false;
            }
          });
          _searchDebounce?.cancel();
          if (query.isEmpty) return;
          _searchDebounce = Timer(const Duration(milliseconds: 450), () {
            if (!mounted) return;
            if (_searchController.text.trim() == query) {
              _performApiSearch(query);
            }
          });
        },
        onSubmitted: (value) {
          _searchDebounce?.cancel();
          final query = value.trim();
          if (query.isNotEmpty) _performApiSearch(query);
        },
      ),
    );
  }

  Future<void> _performApiSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
      _apiSearchResults = null;
    });
    try {
      final youtubeProvider = context.read<YouTubeProvider>();
      final apiIds = <String>{};
      final results = <YouTubeVideo>[];

      // Buscar solo en el playlist de DevLokos (coincidencia parcial: "joe" encuentra "Joel")
      final playlistResults = await youtubeProvider.searchInPlaylistWithFullFetch(query);
      for (final v in playlistResults) {
        if (apiIds.add(v.videoId)) results.add(v);
      }

      if (mounted) {
        setState(() {
          _apiSearchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Error al buscar. Intenta de nuevo.';
          _isSearching = false;
          _apiSearchResults = null;
        });
      }
    }
  }

  Widget _buildInitialLoading() {
    return Container(
      decoration: const BoxDecoration(
        color: BrandColors.primaryBlack,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: BrandColors.primaryBlack,
                borderRadius: BorderRadius.circular(60),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(57),
                child: Image.asset(
                  'assets/icons/devlokos_icon.webp',
                  width: 114,
                  height: 114,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Indicador de progreso circular
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
              ),
            ),
            const SizedBox(height: 24),
            
            // Mensaje de loading
            Text(
              _loadingMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: BrandColors.primaryWhite,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Mensaje secundario
            Text(
              'Preparando los mejores episodios para ti',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.grayMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitialLoading) {
      return _buildInitialLoading();
    }

    // Búsqueda API tiene prioridad; no bloquear home por EpisodeBloc
    if (_apiSearchResults != null || _isSearching || _searchError != null) {
      return _buildSearchResultsContent();
    }

    return Consumer<YouTubeProvider>(
      builder: (context, youtubeProvider, _) {
        if (youtubeProvider.videos.isEmpty &&
            youtubeProvider.errorMessage != null) {
          return AppErrorState(
            title: 'Error al cargar videos',
            message: youtubeProvider.errorMessage!,
            onRetry: () {
              setState(() => _isInitialLoading = true);
              _loadYouTubeVideos();
            },
          );
        }

        if (youtubeProvider.videos.isEmpty) {
          return AppEmptyState(
            icon: Icons.podcasts_outlined,
            title: 'No hay episodios disponibles',
            subtitle: 'Vuelve a intentarlo en un momento.',
            showRetry: true,
            onRetry: () {
              setState(() => _isInitialLoading = true);
              _loadYouTubeVideos();
            },
          );
        }

        if (_discoverVideos == null) {
          _generateDiscoverVideos(youtubeProvider.videos);
        }
        if (_allVideosSorted == null) {
          _generateSortedVideos(youtubeProvider.videos);
        }

        final hPad = Responsive.horizontalPadding(context);
        return SingleChildScrollView(
          controller: _mainScrollController,
          padding: EdgeInsets.only(
            left: hPad,
            right: hPad,
            bottom: MediaQuery.of(context).padding.bottom + 100.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLatestEpisodeSection(),
              const SizedBox(height: 28),
              _buildFeaturedSection(),
              const SizedBox(height: 32),
              _buildEpisodesSection(),
              _buildPaginationFooter(youtubeProvider),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24.0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(YouTubeProvider youtubeProvider) {
    final showSpinner =
        _isLoadingMoreEpisodes || (youtubeProvider.isLoading && youtubeProvider.hasMoreVideos);
    if (!showSpinner && !youtubeProvider.hasMoreVideos) {
      return const SizedBox(height: 8);
    }
    if (!showSpinner) return const SizedBox(height: 8);

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: BrandColors.primaryOrange,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLatestEpisodeSection() {
    final latest = _latestEpisode;
    if (latest == null) return const SizedBox.shrink();

    final tablet = Responsive.isTablet(context);
    final thumbHeight = tablet ? 180.0 : 160.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Último episodio',
          padding: EdgeInsets.only(left: 4, bottom: 4),
        ),
        const SizedBox(height: 12),
        YouTubeVideoCard(
          video: latest,
          onTap: () => _onVideoTap(latest),
          showChannelTitle: false,
          thumbnailHeight: thumbHeight,
        ),
      ],
    );
  }

  YouTubeVideo? get _latestEpisode {
    final sorted = _allVideosSorted;
    if (sorted != null && sorted.isNotEmpty) {
      final byDate = List<YouTubeVideo>.from(sorted)
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return byDate.first;
    }
    final discover = _discoverVideos;
    if (discover == null || discover.isEmpty) return null;
    return discover.first;
  }

  Widget _buildFeaturedSection() {
    final discoverVideos = _discoverVideos;
    if (discoverVideos == null || discoverVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    // Evitar duplicar el último episodio justo debajo del hero
    final latestId = _latestEpisode?.videoId;
    final railVideos = latestId == null
        ? discoverVideos
        : discoverVideos.where((v) => v.videoId != latestId).toList();
    if (railVideos.isEmpty) return const SizedBox.shrink();

    final tablet = Responsive.isTablet(context);
    final wide = Responsive.isWide(context);
    final cardWidth = wide ? 300.0 : (tablet ? 280.0 : 236.0);
    const gap = 12.0;
    final thumbHeight = tablet ? 140.0 : 118.0;
    final railHeight = tablet ? 220.0 : 188.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Recientes',
          padding: EdgeInsets.only(left: 4, bottom: 4),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: railHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _pauseDiscoverAutoScrollTemporarily();
              }
              return false;
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: ListView.builder(
                controller: _discoverScrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: railVideos.length,
                itemBuilder: (context, index) {
                  final video = railVideos[index];
                  return SizedBox(
                    width: cardWidth,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < railVideos.length - 1 ? gap : 0,
                      ),
                      child: YouTubeVideoCard(
                        video: video,
                        onTap: () => _onVideoTap(video),
                        showChannelTitle: false,
                        thumbnailHeight: thumbHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsContent() {
    if (_isSearching) {
      return const AppLoading(message: 'Buscando episodios...');
    }

    if (_searchError != null) {
      return AppErrorState(
        message: _searchError!,
        onRetry: () => _performApiSearch(_searchQuery),
      );
    }

    if (_apiSearchResults == null) {
      return const AppEmptyState(
        icon: Icons.search_rounded,
        title: 'Escribe para buscar',
        subtitle: 'Busca por invitado, tema o número de episodio',
      );
    }

    final searchResults = _apiSearchResults!;
    if (searchResults.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        subtitle: 'Intenta con otros términos de búsqueda',
      );
    }

    final hPad = Responsive.horizontalPadding(context);
    final cols = Responsive.episodeCrossAxisCount(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
          child: SectionHeader(
            title: 'Resultados (${searchResults.length})',
            padding: EdgeInsets.zero,
          ),
        ),
        Expanded(
          child: cols == 1
              ? ListView.builder(
                  padding: EdgeInsets.only(
                    left: hPad,
                    right: hPad,
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final video = searchResults[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: YouTubeVideoListTile(
                        video: video,
                        onTap: () => _onVideoTap(video),
                      ),
                    );
                  },
                )
              : GridView.builder(
                  padding: EdgeInsets.only(
                    left: hPad,
                    right: hPad,
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 96,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final video = searchResults[index];
                    return YouTubeVideoListTile(
                      video: video,
                      onTap: () => _onVideoTap(video),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEpisodesSection() {
    return Consumer<YouTubeProvider>(
      builder: (context, youtubeProvider, child) {
        final filteredVideos = _filterVideosBySeason(youtubeProvider.videos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Episodios',
              padding: const EdgeInsets.only(left: 4),
              trailing: SeasonFilterDropdown(
                value: _selectedSeason,
                onChanged: _loadMoreVideosForSeason,
              ),
            ),
            const SizedBox(height: 16),
            if (youtubeProvider.isLoading && youtubeProvider.videos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: AppLoading(message: 'Cargando episodios...'),
              )
            else if (filteredVideos.isEmpty)
              AppEmptyState(
                icon: Icons.podcasts_outlined,
                title: 'Sin episodios en $_selectedSeason',
                subtitle: _isLoadingMoreEpisodes || youtubeProvider.isLoading
                    ? 'Buscando episodios de esta temporada...'
                    : PodcastSeasons.emptyMessage(_selectedSeason),
              )
            else
              _buildEpisodesListView(filteredVideos),
          ],
        );
      },
    );
  }

  /// Lista densa de episodios (scroll del SingleChildScrollView padre).
  /// En tablet/iPad usa 2 columnas para aprovechar el ancho.
  Widget _buildEpisodesListView(List<YouTubeVideo> filteredVideos) {
    final cols = Responsive.episodeCrossAxisCount(context);
    if (cols == 1) {
      return Column(
        children: [
          for (final video in filteredVideos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: YouTubeVideoListTile(
                video: video,
                onTap: () => _onVideoTap(video),
              ),
            ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final video in filteredVideos)
              SizedBox(
                width: tileWidth,
                child: YouTubeVideoListTile(
                  video: video,
                  onTap: () => _onVideoTap(video),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onVideoTap(YouTubeVideo video) {
    // Buscar el episodio correspondiente en la base de datos
    final episodeBloc = context.read<EpisodeBloc>();
    Episode? correspondingEpisode;
    
    if (episodeBloc.state is EpisodeLoaded) {
      final episodes = (episodeBloc.state as EpisodeLoaded).episodes;
      try {
        correspondingEpisode = episodes.firstWhere(
          (episode) => episode.youtubeVideoId == video.videoId,
        );
      } catch (e) {
        correspondingEpisode = null;
      }
    }

    // Navegar a la pantalla de detalle usando push para mantener el historial de navegación
    context.push('/episode/${correspondingEpisode?.id ?? video.videoId}', 
      extra: {
        'episode': correspondingEpisode,
        'youtubeVideo': video,
      }
    );
  }

  List<YouTubeVideo> _filterVideosBySeason(List<YouTubeVideo> videos) {
    if (PodcastSeasons.isAll(_selectedSeason)) {
      if (_allVideosSorted != null) {
        // Orden absoluto por fecha para "Todas"
        final byDate = List<YouTubeVideo>.from(_allVideosSorted!)
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        return byDate;
      }
      final sorted = List<YouTubeVideo>.from(videos)
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return sorted;
    }

    final season = PodcastSeasons.byLabel(_selectedSeason);
    final seasonNum = season?.number ?? 2;

    if (_allVideosSorted != null) {
      if (seasonNum == 1 && _s1VideosSorted != null) return _s1VideosSorted!;
      if (seasonNum == 2 && _s2VideosSorted != null) return _s2VideosSorted!;
      if (seasonNum == 3 && _s3VideosSorted != null) return _s3VideosSorted!;
      return [];
    }

    final pattern = PodcastSeasons.patternForLabel(_selectedSeason);
    final filtered = videos.where((v) => v.title.contains(pattern)).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return filtered;
  }

  Future<void> _loadMoreVideosForSeason(String season) async {
    if (!mounted) return;
    setState(() => _selectedSeason = season);
    await _ensureSeasonHasContent();
  }
}
