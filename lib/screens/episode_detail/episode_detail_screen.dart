import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../bloc/episode/episode_bloc_exports.dart';
import '../../providers/youtube_provider.dart';

class EpisodeDetailScreen extends StatefulWidget {
  final String? episodeId;
  final Episode? episode;
  final YouTubeVideo? youtubeVideo;

  const EpisodeDetailScreen({
    super.key,
    this.episodeId,
    this.episode,
    this.youtubeVideo,
  });

  @override
  State<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> {
  YoutubePlayerController? _controller;
  Episode? _currentEpisode;
  YouTubeVideo? _currentYouTubeVideo;
  bool _isPlayerReady = false;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _loadEpisodeData();
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _loadEpisodeData() {
    // Si ya tenemos los datos, usarlos directamente
    if (widget.episode != null) {
      _currentEpisode = widget.episode;
    }
    if (widget.youtubeVideo != null) {
      _currentYouTubeVideo = widget.youtubeVideo;
    }

    // Si tenemos un episodeId, cargar los datos
    if (widget.episodeId != null && widget.episode == null) {
      _loadEpisodeFromId();
    }

    // Inicializar el reproductor si tenemos un video
    _initializePlayer();
  }

  void _loadEpisodeFromId() {
    final episodeBloc = context.read<EpisodeBloc>();
    if (episodeBloc.state is EpisodeLoaded) {
      final episodes = (episodeBloc.state as EpisodeLoaded).episodes;
      final foundEpisode = episodes.firstWhere(
        (ep) => ep.id == widget.episodeId,
        orElse: () => Episode(
          id: '',
          title: '',
          description: '',
          thumbnailUrl: '',
          youtubeVideoId: '',
          duration: '0:00',
          publishedDate: DateTime.now(),
          category: '',
          tags: [],
          isFeatured: false,
        ),
      );

      if (foundEpisode.id.isNotEmpty) {
        setState(() {
          _currentEpisode = foundEpisode;
          _currentYouTubeVideo = YouTubeVideo(
            videoId: foundEpisode.youtubeVideoId,
            title: foundEpisode.title,
            description: foundEpisode.description,
            thumbnailUrl: foundEpisode.thumbnailUrl,
            channelTitle: 'DevLokos',
            publishedAt: foundEpisode.publishedDate,
            position: 0,
          );
        });
        _initializePlayer();
      }
    }
  }

  void _initializePlayer() {
    final videoId = _getVideoId();
    if (videoId.isNotEmpty) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          loop: false,
          enableCaption: true,
          enableJavaScript: true,
          strictRelatedVideos: false,
        ),
      );

      _controller?.listen(_onPlayerStateChange);
    }
  }

  void _onPlayerStateChange(YoutubePlayerValue value) {
    setState(() {
      _isPlayerReady = true;
      _playerError = null;
    });
  }

  String _getVideoId() {
    return _currentYouTubeVideo?.videoId ?? 
           widget.youtubeVideo?.videoId ?? 
           _currentEpisode?.youtubeVideoId ?? 
           widget.episode?.youtubeVideoId ?? 
           '';
  }

  String _getPublishedDate() {
    final publishedAt = _currentYouTubeVideo?.publishedAt ?? 
                       widget.youtubeVideo?.publishedAt ?? 
                       _currentEpisode?.publishedDate ?? 
                       widget.episode?.publishedDate;
    
    if (publishedAt != null) {
      try {
        DateTime date;
        if (publishedAt is DateTime) {
          date = publishedAt;
        } else {
          date = DateTime.parse(publishedAt.toString());
        }
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return publishedAt.toString();
      }
    }
    return 'Fecha no disponible';
  }

  Future<void> _shareEpisode() async {
    final videoId = _getVideoId();
    if (videoId.isNotEmpty) {
      final url = 'https://www.youtube.com/watch?v=$videoId';
      final episodeTitle = _currentYouTubeVideo?.title ?? 
                          _currentEpisode?.title ?? 
                          'Episodio DevLokos';
      
      await Share.share('¡Mira este episodio de DevLokos! "$episodeTitle"\n$url');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede compartir, ID de video no disponible.'),
          backgroundColor: BrandColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _currentEpisode?.title ?? 'Detalle del Episodio',
      ),
      body: Container(
        color: BrandColors.primaryBlack,
        child: SafeArea(
          child: BlocBuilder<EpisodeBloc, EpisodeState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVideoPlayer(),
                    const SizedBox(height: 24),
                    _buildEpisodeInfo(),
                    const SizedBox(height: 32),
                    _buildRelatedEpisodes(state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final videoId = _getVideoId();
    
    if (videoId.isEmpty) {
      return _buildErrorPlayer('No hay video disponible');
    }

    if (_controller == null) {
      return _buildLoadingPlayer();
    }

    if (_playerError != null) {
      return _buildErrorPlayer(_playerError!);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: BrandColors.blackShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _controller!,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }

  Widget _buildLoadingPlayer() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: BrandColors.blackLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
            ),
            SizedBox(height: 12),
            Text(
              'Cargando video...',
              style: TextStyle(
                color: BrandColors.grayMedium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlayer(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: BrandColors.blackLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: BrandColors.grayMedium,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Error al cargar el video',
              style: const TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: BrandColors.grayMedium,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _playerError = null;
                  _isPlayerReady = false;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primaryOrange,
                foregroundColor: BrandColors.primaryWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeInfo() {
    final title = _currentYouTubeVideo?.title ?? 
                 widget.youtubeVideo?.title ?? 
                 _currentEpisode?.title ?? 
                 'Título no disponible';
    
    final description = _currentYouTubeVideo?.description ?? 
                      widget.youtubeVideo?.description ?? 
                      _currentEpisode?.description ?? 
                      'Descripción no disponible';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: BrandColors.primaryWhite,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: BrandColors.grayMedium,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _getPublishedDate(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BrandColors.grayMedium,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Descripción',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: BrandColors.primaryWhite,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: BrandColors.grayLight,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.share,
          label: 'Compartir',
          onPressed: _shareEpisode,
        ),
        _buildActionButton(
          icon: Icons.favorite_border,
          label: 'Favorito',
          onPressed: () {
            // TODO: Implementar lógica de favoritos
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidad de favoritos en desarrollo'),
                backgroundColor: BrandColors.primaryOrange,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: BrandColors.primaryOrange, size: 28),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: BrandColors.grayMedium,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedEpisodes(EpisodeState state) {
    List<Episode> relatedEpisodes = [];
    if (state is EpisodeSelected) {
      relatedEpisodes = state.relatedEpisodes;
    }

    if (relatedEpisodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EPISODIOS RELACIONADOS',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: BrandColors.primaryWhite,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: relatedEpisodes.length,
          itemBuilder: (context, index) {
            final episode = relatedEpisodes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                color: BrandColors.blackLight,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      episode.thumbnailUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: BrandColors.grayMedium,
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: BrandColors.primaryOrange,
                          ),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    episode.title,
                    style: const TextStyle(
                      color: BrandColors.primaryWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    episode.description,
                    style: const TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // Navegar al detalle del episodio relacionado
                    context.read<EpisodeBloc>().add(SelectEpisode(episodeId: episode.id));
                    // Reemplazar la ruta actual para que el botón de retroceso funcione correctamente
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => EpisodeDetailScreen(episodeId: episode.id),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}