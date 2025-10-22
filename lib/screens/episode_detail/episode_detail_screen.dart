import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';
import '../../bloc/episode/episode_bloc_exports.dart';
import '../../providers/youtube_provider.dart';
import '../../config/environment_config.dart';
import 'full_episode_screen.dart';

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

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> with WidgetsBindingObserver {
  Episode? _currentEpisode;
  YouTubeVideo? _currentYouTubeVideo;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEpisodeData();
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

    // Inicializar el controlador de YouTube
    _initializeYouTubeController();
  }

  void _initializeYouTubeController() {
    final videoId = _currentYouTubeVideo?.videoId ?? widget.youtubeVideo?.videoId ?? '';
    
    if (videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
    }
  }

  void _loadEpisodeFromId() {
    // Buscar el episodio en el bloc
    final episodeBloc = context.read<EpisodeBloc>();
    if (episodeBloc.state is EpisodeLoaded) {
      final episodes = (episodeBloc.state as EpisodeLoaded).episodes;
      try {
        _currentEpisode = episodes.firstWhere(
          (episode) => episode.id == widget.episodeId,
        );
      } catch (e) {
        _currentEpisode = null;
      }
    }

    // Buscar el video de YouTube correspondiente
    final youtubeProvider = context.read<YouTubeProvider>();
    if (_currentEpisode?.youtubeVideoId != null) {
      try {
        _currentYouTubeVideo = youtubeProvider.videos.firstWhere(
          (video) => video.videoId == _currentEpisode!.youtubeVideoId,
        );
      } catch (e) {
        _currentYouTubeVideo = null;
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Forzar reconstrucción del widget cuando cambie la orientación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    final fullTitle = _currentYouTubeVideo?.title ?? widget.youtubeVideo?.title ?? _currentEpisode?.title ?? widget.episode?.title ?? 'Episodio';
    
    // Dividir por el primer ||
    final parts = fullTitle.split('||');
    if (parts.length > 1) {
      return parts[0].trim();
    }
    
    return fullTitle;
  }

  String _getVideoTitle() {
    final fullTitle = _currentYouTubeVideo?.title ?? widget.youtubeVideo?.title ?? _currentEpisode?.title ?? widget.episode?.title ?? 'Sin título';
    
    // Dividir por el primer ||
    final parts = fullTitle.split('||');
    if (parts.length > 1) {
      // Tomar todo desde el primer || hacia la derecha
      return parts.sublist(1).join('||').trim();
    }
    
    return fullTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(
        title: _getAppBarTitle(),
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reproductor de video
              _buildVideoPlayer(),
              const SizedBox(height: 24),

              // Información del episodio
              _buildEpisodeInfo(),
              const SizedBox(height: 24),

              // Descripción del episodio
              _buildEpisodeDescription(),
              const SizedBox(height: 24),

              // Botón de compartir
              _buildShareButton(),
              const SizedBox(height: 24),

              // Información del episodio de la base de datos
              if ((_currentEpisode ?? widget.episode) != null) ...[
                _buildDatabaseEpisodeInfo(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final videoId = _currentYouTubeVideo?.videoId ?? widget.youtubeVideo?.videoId;
    if (videoId == null || videoId.isEmpty || _controller == null) {
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
              Icon(
                Icons.play_circle_outline,
                color: BrandColors.grayMedium,
                size: 48,
              ),
              SizedBox(height: 8),
              Text(
                'Video no disponible',
                style: TextStyle(
                  color: BrandColors.grayMedium,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: BrandColors.blackShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: BrandColors.primaryOrange,
              progressColors: const ProgressBarColors(
                playedColor: BrandColors.primaryOrange,
                handleColor: BrandColors.primaryOrange,
              ),
              onReady: () {
                print('✅ Reproductor de YouTube listo');
              },
              onEnded: (data) {
                print('🏁 Video terminado');
              },
            ),
            // Logo de DevLokos para cubrir el botón de pantalla completa nativo
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FullEpisodeScreen(
                        episode: _currentEpisode ?? widget.episode,
                        youtubeVideo: _currentYouTubeVideo ?? widget.youtubeVideo,
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BrandColors.primaryOrange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: BrandColors.primaryOrange,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeInfo() {
    final title = _getVideoTitle();
    final publishedAt = _currentYouTubeVideo?.publishedAt ?? widget.youtubeVideo?.publishedAt ?? _currentEpisode?.publishedDate ?? widget.episode?.publishedDate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: BrandColors.blackShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: BrandColors.primaryWhite,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (publishedAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: BrandColors.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(publishedAt),
                  style: const TextStyle(
                    color: BrandColors.grayMedium,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if ((_currentEpisode?.duration ?? widget.episode?.duration) != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: BrandColors.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  (_currentEpisode?.duration ?? widget.episode?.duration)!,
                  style: const TextStyle(
                    color: BrandColors.grayMedium,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEpisodeDescription() {
    final description = _currentYouTubeVideo?.description ?? widget.youtubeVideo?.description ?? _currentEpisode?.description ?? widget.episode?.description ?? 'Sin descripción disponible.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: BrandColors.blackShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: BrandColors.primaryWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return GradientButton(
      onPressed: _shareEpisode,
      text: 'Compartir Episodio',
      icon: Icons.share,
      gradient: BrandColors.primaryGradient,
      textColor: BrandColors.primaryWhite,
    );
  }

  void _shareEpisode() {
    final episodeTitle = _getVideoTitle();
    final appBarTitle = _getAppBarTitle();
    
    // Extraer información del título para crear un mensaje más atractivo
    String learningContent = '';
    if (episodeTitle.contains('||')) {
      final parts = episodeTitle.split('||');
      if (parts.length > 1) {
        learningContent = parts[1].trim();
      }
    } else {
      learningContent = episodeTitle;
    }
    
    // Crear mensaje más atractivo
    final shareText = '''
🎧 Descubre el episodio "$appBarTitle", en donde aprenderás $learningContent

📱 Descarga la aplicación DevLokos y accede a cientos de episodios:
${EnvironmentConfig.onelinkUrl}

#DevLokos #Podcast #Tech #Aprendizaje
''';

    Share.share(shareText);
  }

  Widget _buildDatabaseEpisodeInfo() {
    final episode = _currentEpisode ?? widget.episode!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: BrandColors.blackShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Episodio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: BrandColors.primaryWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID', episode.id),
          _buildInfoRow('YouTube ID', episode.youtubeVideoId),
          _buildInfoRow('Destacado', episode.isFeatured ? 'Sí' : 'No'),
          _buildInfoRow('Categoría', episode.category),
          _buildInfoRow('Publicado', _formatDate(episode.publishedDate)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: BrandColors.grayMedium,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}