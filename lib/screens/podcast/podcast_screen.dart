import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/episode/episode_bloc_exports.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../providers/youtube_provider.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/custom_app_bar.dart';
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
  String _selectedSeason = 'Temporada 2';
  List<YouTubeVideo>? _discoverVideos; // Cache para videos de descubrimiento
  List<YouTubeVideo>? _allVideosSorted; // Cache para todos los videos ordenados por fecha
  List<YouTubeVideo>? _s1VideosSorted; // Cache para videos de temporada 1 ordenados
  List<YouTubeVideo>? _s2VideosSorted; // Cache para videos de temporada 2 ordenados
  bool _isInitialLoading = true; // Estado de carga inicial
  String _loadingMessage = 'Cargando videos...'; // Mensaje de loading
  bool _hasLoaded = false; // Flag para asegurar que solo se carga una vez
  final ScrollController _episodesScrollController = ScrollController();
  bool _isLoadingMoreEpisodes = false;

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
    
    // Actualizar mensaje de loading
    if (mounted) {
      setState(() {
        _loadingMessage = 'CARGANDO EPISODIOS';
      });
    }
    
    // Carga inicial rápida: solo 30 videos para mostrar la UI rápidamente
    await youtubeProvider.loadVideos(initialLoad: true, maxResults: 30);
    
    // Generar videos de descubrimiento con los videos iniciales
    _generateDiscoverVideos(youtubeProvider.videos);
    
    // Generar videos ordenados con los videos iniciales
    _generateSortedVideos(youtubeProvider.videos);
    
    // Finalizar loading inicial para mostrar la UI inmediatamente
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
    
    // Cargar más videos en segundo plano sin bloquear la UI
    _loadMoreVideosInBackground(youtubeProvider);
  }
  
  /// Carga más videos en segundo plano sin bloquear la UI
  Future<void> _loadMoreVideosInBackground(YouTubeProvider provider) async {
    // Cargar más videos gradualmente en segundo plano
    // Esto permite que el usuario vea contenido mientras se cargan más episodios
    int loadedBatches = 0;
    const maxInitialBatches = 3; // Cargar 3 batches adicionales en segundo plano (30 + 60 = 90 videos)
    
    while (loadedBatches < maxInitialBatches && provider.hasMoreVideos && mounted) {
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeña pausa entre batches
      
      if (!mounted) break;
      
      await provider.loadMoreVideos(batchSize: 30);
      loadedBatches++;
      
      // Regenerar caches con los nuevos videos
      if (mounted) {
        _generateSortedVideos(provider.videos);
        _generateDiscoverVideos(provider.videos);
      }
    }
    
    print('✅ Carga en segundo plano completada: ${provider.videos.length} videos totales');
  }

        void _generateDiscoverVideos(List<YouTubeVideo> allVideos) {
          // Regenerar siempre para incluir nuevos videos cargados
          if (allVideos.isNotEmpty) {
            // Filtrar videos con títulos válidos (no vacíos, no "Sin título")
            final validVideos = allVideos.where((video) => 
              video.title.isNotEmpty && 
              video.title.trim().isNotEmpty &&
              video.title != 'Sin título'
            ).toList();
            
            print('🎲 Videos válidos para descubrimiento: ${validVideos.length} de ${allVideos.length} videos totales');
            
            if (validVideos.isNotEmpty) {
              // Mezclar videos válidos y tomar 4 aleatorios
              final shuffledVideos = List<YouTubeVideo>.from(validVideos);
              shuffledVideos.shuffle();
              _discoverVideos = shuffledVideos.take(4).toList();
              print('🎲 Videos de descubrimiento regenerados: ${_discoverVideos!.length} videos válidos');
            } else {
              // Si no hay videos válidos, usar todos los videos como fallback
              final shuffledVideos = List<YouTubeVideo>.from(allVideos);
              shuffledVideos.shuffle();
              _discoverVideos = shuffledVideos.take(4).toList();
              print('⚠️ Fallback: Usando todos los videos para descubrimiento: ${_discoverVideos!.length}');
            }
          }
        }

  void _generateSortedVideos(List<YouTubeVideo> allVideos) {
    if (allVideos.isNotEmpty) {
      // Eliminar duplicados basándose en el videoId
      final uniqueVideos = <String, YouTubeVideo>{};
      for (final video in allVideos) {
        uniqueVideos[video.videoId] = video;
      }
      final deduplicatedVideos = uniqueVideos.values.toList();
      
      // Separar videos por temporada
      final s1Videos = deduplicatedVideos.where((v) => v.title.contains('S1')).toList();
      final s2Videos = deduplicatedVideos.where((v) => v.title.contains('S2')).toList();
      
      // Ordenar cada temporada por fecha descendente (más reciente primero)
      s1Videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      s2Videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      // Para "TODAS": S2 primero (más reciente), luego S1
      _allVideosSorted = [...s2Videos, ...s1Videos];
      
      // Cache para cada temporada
      _s1VideosSorted = s1Videos;
      _s2VideosSorted = s2Videos;
      
      print('📅 Videos ordenados por fecha regenerados:');
      print('  - Todos (S2 + S1): ${_allVideosSorted!.length} videos');
      print('  - Temporada 1: ${_s1VideosSorted!.length} videos');
      print('  - Temporada 2: ${_s2VideosSorted!.length} videos');
      
      // Mostrar los primeros 3 videos ordenados
      if (_allVideosSorted!.isNotEmpty) {
        print('📅 Primeros 3 videos ordenados (S2 primero, luego S1):');
        for (int i = 0; i < _allVideosSorted!.length && i < 3; i++) {
          final video = _allVideosSorted![i];
          print('  ${i + 1}. ${video.title} - ${video.publishedAt}');
        }
      }
    }
  }

  void _setupScrollListener() {
    _episodesScrollController.addListener(() {
      if (_episodesScrollController.position.pixels >= 
          _episodesScrollController.position.maxScrollExtent * 0.8) {
        // Cuando el usuario llega al 80% del scroll, cargar más videos
        if (!_isLoadingMoreEpisodes && mounted) {
          final youtubeProvider = context.read<YouTubeProvider>();
          if (youtubeProvider.hasMoreVideos && !youtubeProvider.isLoading) {
            _isLoadingMoreEpisodes = true;
            youtubeProvider.loadMoreVideos(batchSize: 30).then((_) {
              _isLoadingMoreEpisodes = false;
              // Regenerar caches con los nuevos videos
              if (mounted) {
                setState(() {
                  _generateSortedVideos(youtubeProvider.videos);
                });
              }
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _episodesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    return PopScope(
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
      child: SearchBarWidget(
        controller: _searchController,
        hintText: 'Buscar episodios, invitado o tema...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
      ),
    );
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
                  'assets/icons/devlokos_icon.png',
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
    // Mostrar loading inicial si aún no se han cargado los videos
    if (_isInitialLoading) {
      return _buildInitialLoading();
    }
    
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
          final episodes = state is EpisodeLoaded ? state.filteredEpisodes : (state as EpisodeSearching).episodes;
          final featuredEpisodes = state is EpisodeLoaded ? state.featuredEpisodes : [];

          // Si hay una búsqueda activa, usar búsqueda directa
          if (_searchQuery.isNotEmpty) {
            return _buildSearchResultsContent();
          }

          // Si no hay búsqueda, mostrar contenido normal
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
                    'No hay episodios disponibles',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BrandColors.primaryWhite,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              bottom: MediaQuery.of(context).padding.bottom + 100.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeaturedSection(featuredEpisodes.cast<Episode>()),
                const SizedBox(height: 32),
                _buildEpisodesSection(episodes),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 50.0),
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

  Widget _buildFeaturedSection(List<Episode> featuredEpisodes) {
    return Consumer<YouTubeProvider>(
      builder: (context, youtubeProvider, child) {
        // Usar videos cacheados si están disponibles, sino generar nuevos
        if (_discoverVideos == null && youtubeProvider.videos.isNotEmpty) {
          _generateDiscoverVideos(youtubeProvider.videos);
        }
        
        final discoverVideos = _discoverVideos;
        if (discoverVideos == null || discoverVideos.isEmpty) {
          print('❌ No hay videos de descubrimiento disponibles');
          return const SizedBox.shrink();
        }
        
        print('🎲 Mostrando ${discoverVideos.length} videos de descubrimiento cacheados');
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: BrandColors.primaryOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Descubre',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primaryWhite,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  clipBehavior: Clip.none,
                  itemCount: discoverVideos.length,
                  itemBuilder: (context, index) {
                    final video = discoverVideos[index];
                    return SizedBox(
                      width: 300,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < discoverVideos.length - 1 ? 16 : 0,
                        ),
                        child: YouTubeVideoCard(
                          video: video,
                          onTap: () => _onVideoTap(video),
                          showChannelTitle: false,
                          thumbnailHeight: 140,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
      },
    );
  }

  Widget _buildSearchResultsContent() {
    return Consumer<YouTubeProvider>(
      builder: (context, youtubeProvider, child) {
        // Realizar búsqueda directamente en los videos de YouTube
        final searchResults = _performDirectSearch(_searchQuery, youtubeProvider.videos);
        
        if (searchResults.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    color: BrandColors.grayMedium,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron episodios',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BrandColors.primaryWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta con otros términos de búsqueda',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BrandColors.grayMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sugerencias:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: BrandColors.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Busca por nombre del invitado\n• Busca por tema del episodio\n• Busca por número de episodio',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BrandColors.grayMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        // Mostrar resultados como una lista simple
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: BrandColors.primaryOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Resultados (${searchResults.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BrandColors.primaryWhite,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 100.0, // Aumentar padding significativamente
                ),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final video = searchResults[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: YouTubeVideoCard(
                      video: video,
                      onTap: () => _onVideoTap(video),
                      thumbnailHeight: 200,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Realiza búsqueda directa en los videos de YouTube
  List<YouTubeVideo> _performDirectSearch(String query, List<YouTubeVideo> videos) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase().trim();
    print('🔍 Búsqueda directa: "$lowercaseQuery" en ${videos.length} videos');
    
    final searchResults = videos.where((video) {
      // Filtrar videos con títulos vacíos o "Sin título"
      if (video.title.isEmpty || video.title.toLowerCase() == 'sin título') {
        return false;
      }
      
      final titleLower = video.title.toLowerCase();
      final descriptionLower = video.description.toLowerCase();
      
      // Búsqueda en el título completo
      if (titleLower.contains(lowercaseQuery)) {
        print('✅ Encontrado en título: ${video.title}');
        return true;
      }
      
      // Búsqueda en las partes del título separadas por ||
      // Formato: "DevLokos S1 Ep019 || Descripción del episodio || Invitado"
      final titleParts = titleLower.split('||');
      for (final part in titleParts) {
        final cleanPart = part.trim();
        if (cleanPart.contains(lowercaseQuery)) {
          print('✅ Encontrado en parte del título: $cleanPart');
          return true;
        }
      }
      
      // Búsqueda en la descripción
      if (descriptionLower.contains(lowercaseQuery)) {
        print('✅ Encontrado en descripción: ${video.title}');
        return true;
      }
      
      return false;
    }).toList();
    
    print('✅ Búsqueda directa: ${searchResults.length} resultados encontrados');
    return searchResults;
  }


  Widget _buildEpisodesSection(List<Episode> episodes) {
    return Consumer<YouTubeProvider>(
      builder: (context, youtubeProvider, child) {
        // Mostrar videos filtrados por temporada
        final filteredVideos = _filterVideosBySeason(youtubeProvider.videos);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: BrandColors.primaryOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Episodios',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primaryWhite,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSeasonFilter(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mostrar videos de YouTube en lugar de episodios tradicionales
            if (youtubeProvider.isLoading && youtubeProvider.videos.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: BrandColors.primaryOrange,
                  ),
                ),
              )
            else if (youtubeProvider.errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: BrandColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar videos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: BrandColors.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        youtubeProvider.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BrandColors.grayMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => youtubeProvider.loadVideos(refresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.primaryOrange,
                          foregroundColor: BrandColors.primaryWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildEpisodesListView(filteredVideos, youtubeProvider),
          ],
        );
      },
    );
  }

  /// Construye la lista de episodios con scroll infinito
  Widget _buildEpisodesListView(List<YouTubeVideo> filteredVideos, YouTubeProvider youtubeProvider) {
    return ListView.builder(
      controller: _episodesScrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 100.0,
      ),
      itemCount: filteredVideos.length + (youtubeProvider.hasMoreVideos ? 1 : 0),
      itemBuilder: (context, index) {
        // Mostrar indicador de carga al final si hay más videos
        if (index == filteredVideos.length) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: youtubeProvider.isLoading || _isLoadingMoreEpisodes
                ? const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: BrandColors.primaryOrange,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        if (!_isLoadingMoreEpisodes) {
                          _isLoadingMoreEpisodes = true;
                          await youtubeProvider.loadMoreVideos(batchSize: 30);
                          if (mounted) {
                            setState(() {
                              _generateSortedVideos(youtubeProvider.videos);
                              _isLoadingMoreEpisodes = false;
                            });
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        decoration: BoxDecoration(
                          color: BrandColors.blackLight.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: BrandColors.primaryOrange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: BrandColors.primaryOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cargar más episodios',
                              style: TextStyle(
                                color: BrandColors.primaryWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          );
        }

        final video = filteredVideos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: YouTubeVideoCard(
            video: video,
            onTap: () => _onVideoTap(video),
            thumbnailHeight: 200,
          ),
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

  Widget _buildSeasonFilter() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedSeason,
        dropdownColor: BrandColors.blackLight,
        style: const TextStyle(
          color: BrandColors.primaryWhite,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        underline: const SizedBox(),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: BrandColors.primaryOrange.withOpacity(0.9),
          size: 20,
        ),
        items: ['Temporada 1', 'Temporada 2'].map((String season) {
          return DropdownMenuItem<String>(
            value: season,
            child: Text(season),
          );
        }).toList(),
        onChanged: (String? newValue) async {
          if (newValue != null) {
            setState(() {
              _selectedSeason = newValue;
            });
            
            // Cargar más videos para la temporada seleccionada si es necesario
            await _loadMoreVideosForSeason(newValue);
          }
        },
      ),
    );
  }

  List<YouTubeVideo> _filterVideosBySeason(List<YouTubeVideo> videos) {
    List<YouTubeVideo> allFilteredVideos;
    
    // Usar videos cacheados si están disponibles
    if (_allVideosSorted != null) {
      if (_selectedSeason == 'Temporada 1' && _s1VideosSorted != null) {
        allFilteredVideos = _s1VideosSorted!;
      } else if (_selectedSeason == 'Temporada 2' && _s2VideosSorted != null) {
        allFilteredVideos = _s2VideosSorted!;
      } else {
        allFilteredVideos = [];
      }
    } else {
      // Fallback: ordenar videos en tiempo real si no hay cache
      final seasonPattern = _selectedSeason == 'Temporada 1' ? 'S1' : 'S2';
      allFilteredVideos = videos.where((video) => 
        video.title.contains(seasonPattern)
      ).toList();
      
      // Ordenar por fecha de publicación descendente (más reciente primero)
      allFilteredVideos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      print('📅 Videos ordenados en tiempo real (${_selectedSeason}): ${allFilteredVideos.length} videos');
    }
    
    // No limitar la cantidad - mostrar todos los videos disponibles
    // La paginación se manejará con scroll infinito
    print('📄 Mostrando ${allFilteredVideos.length} videos de ${_selectedSeason}');
    
    return allFilteredVideos;
  }

  Future<void> _loadMoreVideosForSeason(String season) async {
    final youtubeProvider = context.read<YouTubeProvider>();
    final seasonPattern = season == 'Temporada 1' ? 'S1' : 'S2';
    final currentSeasonVideos = youtubeProvider.videos.where((v) => v.title.contains(seasonPattern)).length;
    
    print('🔍 Temporada seleccionada: $season - Actualmente: $currentSeasonVideos videos');
    
    // Cargar solo un batch adicional si hay pocos videos de la temporada seleccionada
    // El scroll infinito se encargará de cargar más cuando sea necesario
    if (currentSeasonVideos < 10 && youtubeProvider.hasMoreVideos && !youtubeProvider.isLoading) {
      try {
        await youtubeProvider.loadMoreVideos(batchSize: 30);
        
        // Regenerar caches con los nuevos videos
        _generateSortedVideos(youtubeProvider.videos);
        
        final updatedSeasonVideos = youtubeProvider.videos.where((v) => v.title.contains(seasonPattern)).length;
        print('✅ Carga rápida para $season completada - Total videos: $updatedSeasonVideos');
      } catch (e) {
        print('❌ Error en _loadMoreVideosForSeason: $e');
      }
    }
  }
}
