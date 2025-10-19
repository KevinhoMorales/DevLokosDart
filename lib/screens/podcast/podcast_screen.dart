import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
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
    with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Cargar episodios y videos de YouTube después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEpisodes();
      _loadYouTubeVideos();
    });
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
    setState(() {
      _loadingMessage = 'CARGANDO EPISODIOS';
    });
    
    await youtubeProvider.loadVideos();
    
    // Cargar más videos si no tenemos suficientes de todas las temporadas
    await _ensureEnoughVideosForAllSeasons(youtubeProvider);
    
    // Generar videos de descubrimiento una sola vez
    _generateDiscoverVideos(youtubeProvider.videos);
    
    // Generar videos ordenados una sola vez
    _generateSortedVideos(youtubeProvider.videos);
    
    // Finalizar loading
    setState(() {
      _isInitialLoading = false;
    });
  }

  void _generateDiscoverVideos(List<YouTubeVideo> allVideos) {
    if (_discoverVideos == null && allVideos.isNotEmpty) {
      final shuffledVideos = List<YouTubeVideo>.from(allVideos);
      shuffledVideos.shuffle();
      _discoverVideos = shuffledVideos.take(4).toList();
      print('🎲 Videos de descubrimiento generados una sola vez: ${_discoverVideos!.length}');
    }
  }

  void _generateSortedVideos(List<YouTubeVideo> allVideos) {
    if (allVideos.isNotEmpty) {
      // Separar videos por temporada
      final s1Videos = allVideos.where((v) => v.title.contains('S1')).toList();
      final s2Videos = allVideos.where((v) => v.title.contains('S2')).toList();
      
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

  void _clearDiscoverVideosCache() {
    _discoverVideos = null;
    print('🗑️ Cache de videos de descubrimiento limpiado');
  }

  void _clearAllVideosCache() {
    _discoverVideos = null;
    _allVideosSorted = null;
    _s1VideosSorted = null;
    _s2VideosSorted = null;
    print('🗑️ Todos los caches de videos limpiados');
  }

  Future<void> _ensureEnoughVideosForAllSeasons(YouTubeProvider provider) async {
    // Verificar si tenemos videos de ambas temporadas
    int s1Videos = provider.videos.where((v) => v.title.contains('S1')).length;
    int s2Videos = provider.videos.where((v) => v.title.contains('S2')).length;
    
    print('🔍 Videos iniciales - S1: $s1Videos, S2: $s2Videos');
    
    // Priorizar cargar videos de S2 (por defecto) y luego S1
    int attempts = 0;
    const maxAttempts = 25; // Aumentar intentos para conseguir más videos
    
    while ((s2Videos < 100 || s1Videos < 100) && provider.hasMoreVideos && attempts < maxAttempts) {
      try {
        // Actualizar mensaje de loading
        setState(() {
          _loadingMessage = 'CARGANDO EPISODIOS';
        });
        
        await provider.loadMoreVideos();
        attempts++;
        
        final updatedS1Videos = provider.videos.where((v) => v.title.contains('S1')).length;
        final updatedS2Videos = provider.videos.where((v) => v.title.contains('S2')).length;
        
        print('🔄 Intento $attempts - S1: $updatedS1Videos, S2: $updatedS2Videos');
        
        // Regenerar caches con todos los videos actuales
        _generateSortedVideos(provider.videos);
        s1Videos = updatedS1Videos;
        s2Videos = updatedS2Videos;
        
        // Si ya tenemos suficientes videos de ambas temporadas, podemos salir antes
        if (s2Videos >= 100 && s1Videos >= 100) {
          break;
        }
        
        // Pequeña pausa para evitar sobrecargar la API
        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        print('❌ Error en _ensureEnoughVideosForAllSeasons: $e');
        break; // Salir del loop si hay error
      }
    }
    
    print('✅ Carga completada - S1: $s1Videos, S2: $s2Videos videos');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: const CustomAppBar(title: 'PODCAST'),
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
      padding: const EdgeInsets.all(24.0),
      child: SearchBarWidget(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          // Disparar búsqueda con BLoC
          if (value.isNotEmpty) {
            context.read<EpisodeBloc>().add(SearchEpisodes(query: value));
          } else {
            context.read<EpisodeBloc>().add(const ClearSearch());
          }
          
          // También buscar en videos de YouTube
          if (value.isNotEmpty) {
            context.read<YouTubeProvider>().searchVideos(value);
          } else {
            context.read<YouTubeProvider>().loadVideos(refresh: true);
          }
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
                border: Border.all(
                  color: BrandColors.primaryOrange,
                  width: 3,
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (searchQuery.isEmpty) ...[
                    _buildFeaturedSection(featuredEpisodes.cast<Episode>()),
                    const SizedBox(height: 32),
                  ],
                  _buildEpisodesSection(episodes),
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
              Text(
                'DESCUBRE LOS PODCAST',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BrandColors.primaryWhite,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: discoverVideos.length,
                  itemBuilder: (context, index) {
                    final video = discoverVideos[index];
                    print('🎥 Mostrando video ${index + 1}: ${video.title}');
                    return SizedBox(
                      width: 280, // Ancho fijo para evitar problemas de layout
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < discoverVideos.length - 1 ? 16 : 0,
                        ),
                        child: YouTubeVideoCard(
                          video: video,
                          onTap: () => _onVideoTap(video),
                          showChannelTitle: false,
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

  Widget _buildEpisodesSection(List<Episode> episodes) {
    return Consumer<YouTubeProvider>(
      builder: (context, youtubeProvider, child) {
        // Filtrar videos por temporada
        final filteredVideos = _filterVideosBySeason(youtubeProvider.videos);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _searchQuery.isEmpty ? 'TODOS LOS EPISODIOS' : 'RESULTADO DE BÚSQUEDA',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: BrandColors.primaryWhite,
                      fontSize: 16,
                    ),
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
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredVideos.length + (youtubeProvider.hasMoreVideos ? 1 : 0), // +1 solo si hay más videos en la API
                  itemBuilder: (context, index) {
                    if (index == filteredVideos.length) {
                      // Botón para cargar más videos de la API
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: youtubeProvider.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: BrandColors.primaryOrange,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  await youtubeProvider.loadMoreVideos();
                                  // Regenerar caches con los nuevos videos
                                  _generateSortedVideos(youtubeProvider.videos);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BrandColors.primaryOrange,
                                  foregroundColor: BrandColors.primaryWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cargar más videos'),
                              ),
                      );
                    }

                    final video = filteredVideos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: YouTubeVideoCard(
                        video: video,
                        onTap: () => _onVideoTap(video),
                      ),
                    );
                  },
                ),
          ],
        );
      },
    );
  }

  void _onVideoTap(YouTubeVideo video) {
    // TODO: Implementar navegación al video
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reproduciendo: ${video.title}'),
        backgroundColor: BrandColors.primaryOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSeasonFilter() {
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.primaryOrange, width: 1),
      ),
      child: DropdownButton<String>(
        value: _selectedSeason,
        dropdownColor: BrandColors.cardBackground,
        style: const TextStyle(
          color: BrandColors.primaryWhite,
          fontSize: 12,
        ),
        underline: const SizedBox(),
        items: ['Temporada 1', 'Temporada 2'].map((String season) {
          return DropdownMenuItem<String>(
            value: season,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                season,
                style: const TextStyle(
                  color: BrandColors.primaryWhite,
                  fontSize: 12,
                ),
              ),
            ),
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
    
    // Mostrar los primeros 100 videos de la temporada seleccionada
    final limitedVideos = allFilteredVideos.take(100).toList();
    print('📄 Mostrando ${limitedVideos.length} videos (primeros 100) de ${_selectedSeason}');
    
    return limitedVideos;
  }

  Future<void> _loadMoreVideosForSeason(String season) async {
    final youtubeProvider = context.read<YouTubeProvider>();
    final seasonPattern = season == 'Temporada 1' ? 'S1' : 'S2';
    final currentSeasonVideos = youtubeProvider.videos.where((v) => v.title.contains(seasonPattern)).length;
    
    print('🔍 Cargando más videos para $season - Actualmente: $currentSeasonVideos videos');
    
    // Cargar más videos hasta tener al menos 100 de la temporada seleccionada
    int attempts = 0;
    const maxAttempts = 30; // Aumentar intentos para conseguir más videos
    
    try {
      while (currentSeasonVideos < 100 && youtubeProvider.hasMoreVideos && attempts < maxAttempts) {
        await youtubeProvider.loadMoreVideos();
        attempts++;
        
        // Verificar si hemos ganado videos de la temporada
        final updatedSeasonVideos = youtubeProvider.videos.where((v) => v.title.contains(seasonPattern)).length;
        print('🔄 Intento $attempts - Videos de $season: $updatedSeasonVideos');
        
        // Regenerar caches con los nuevos videos
        _generateSortedVideos(youtubeProvider.videos);
        
        // Si no ganamos videos en este intento, salir para evitar loops infinitos
        if (updatedSeasonVideos == currentSeasonVideos) {
          print('⚠️ No se encontraron más videos de $season, deteniendo carga');
          break;
        }
        
        // Pequeña pausa para evitar sobrecargar la API
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('❌ Error en _loadMoreVideosForSeason: $e');
    }
    
    final finalSeasonVideos = youtubeProvider.videos.where((v) => v.title.contains(seasonPattern)).length;
    print('✅ Carga completada para $season - Total videos: $finalSeasonVideos');
  }
}
