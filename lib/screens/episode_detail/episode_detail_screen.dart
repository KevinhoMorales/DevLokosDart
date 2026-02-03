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
  Duration? _savedPosition;

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
    final youtubeProvider = context.read<YouTubeProvider>();

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

    // Buscar el video de YouTube (episodios o tutoriales)
    final videoId = _currentEpisode?.youtubeVideoId ?? widget.episodeId;
    if (videoId != null) {
      _currentYouTubeVideo = youtubeProvider.getVideoById(videoId);
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoPlayer(),
                const SizedBox(height: 24),
                _buildEpisodeInfo(),
                const SizedBox(height: 20),
                _buildEpisodeDescription(),
                const SizedBox(height: 20),
                _buildShareButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final videoId = _currentYouTubeVideo?.videoId ?? widget.youtubeVideo?.videoId;
    if (videoId == null || videoId.isEmpty || _controller == null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: BrandColors.blackLight.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BrandColors.primaryOrange.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                color: BrandColors.primaryOrange.withOpacity(0.5),
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                'Video no disponible',
                style: TextStyle(
                  color: BrandColors.grayMedium,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: BrandColors.primaryOrange.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 2),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: () async {
                  if (_controller != null) {
                    _savedPosition = _controller!.value.position;
                  }
                  final result = await Navigator.of(context).push<Duration?>(
                    MaterialPageRoute(
                      builder: (context) => FullEpisodeScreen(
                        episode: _currentEpisode ?? widget.episode,
                        youtubeVideo: _currentYouTubeVideo ?? widget.youtubeVideo,
                        initialPosition: _savedPosition,
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                  if (result != null && _controller != null) {
                    _controller!.seekTo(result);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrandColors.primaryOrange.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    color: BrandColors.primaryOrange,
                    size: 22,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: BrandColors.primaryWhite,
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 1.35,
              letterSpacing: 0.2,
            ),
          ),
          if (publishedAt != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: BrandColors.primaryOrange.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(publishedAt),
                  style: TextStyle(
                    color: BrandColors.grayLight.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Descripción',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: BrandColors.primaryWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: BrandColors.grayLight.withOpacity(0.85),
              fontSize: 15,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _shareEpisode,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            gradient: BrandColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: BrandColors.primaryOrange.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.share_rounded,
                color: BrandColors.primaryWhite,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Compartir episodio',
                style: TextStyle(
                  color: BrandColors.primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareEpisode() async {
    final episodeTitle = _getVideoTitle();
    final appBarTitle = _getAppBarTitle();
    final videoId = _currentEpisode?.youtubeVideoId ??
        _currentYouTubeVideo?.videoId ??
        widget.episode?.youtubeVideoId ??
        widget.youtubeVideo?.videoId ??
        '';

    String guest = '';
    if (episodeTitle.contains('||')) {
      final parts = episodeTitle.split('||');
      if (parts.length > 1) {
        guest = parts[1].trim();
      }
    }
    if (guest.isEmpty) guest = episodeTitle;

    final youtubeUrl = videoId.isNotEmpty
        ? 'https://www.youtube.com/watch?v=$videoId'
        : '';

    final buffer = StringBuffer();
    buffer.writeln('🎧 Descubre el episodio "$appBarTitle"${guest.isNotEmpty ? ' con $guest' : ''}');
    buffer.writeln();
    buffer.writeln('📱 Descarga DevLokos y accede a más episodios:');
    buffer.writeln(EnvironmentConfig.onelinkUrl);
    if (youtubeUrl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('▶️ Ver en YouTube:');
      buffer.write(youtubeUrl);
    }
    var shareText = buffer.toString().trim();
    if (shareText.isEmpty) {
      shareText = '🎧 Episodio de DevLokos\n\n📱 Descarga la app: ${EnvironmentConfig.onelinkUrl}';
    }
    try {
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir el episodio'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}