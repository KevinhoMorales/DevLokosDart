import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../utils/responsive.dart';
import '../../widgets/custom_app_bar.dart';
import '../../bloc/episode/episode_bloc_exports.dart';
import '../../providers/youtube_provider.dart';
import '../../config/environment_config.dart';
import 'full_episode_screen.dart';

class EpisodeDetailScreen extends StatefulWidget {
  final String? episodeId;
  final Episode? episode;
  final YouTubeVideo? youtubeVideo;
  final String? playlistTitle;

  const EpisodeDetailScreen({
    super.key,
    this.episodeId,
    this.episode,
    this.youtubeVideo,
    this.playlistTitle,
  });

  @override
  State<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen> with WidgetsBindingObserver {
  Episode? _currentEpisode;
  YouTubeVideo? _currentYouTubeVideo;
  YoutubePlayerController? _controller;
  Duration? _savedPosition;
  bool _descriptionExpanded = false;

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

  String _getFullTitle() {
    return _currentYouTubeVideo?.title ??
        widget.youtubeVideo?.title ??
        _currentEpisode?.title ??
        widget.episode?.title ??
        'Sin título';
  }

  List<String> _titleParts() {
    return _getFullTitle()
        .split('||')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  String _getAppBarTitle() {
    // Prioridad: nombre de playlist (más corto) cuando viene de Tutoriales
    if (widget.playlistTitle != null && widget.playlistTitle!.isNotEmpty) {
      return widget.playlistTitle!;
    }
    final parts = _titleParts();
    // "DevLokos S2 Ep065 || Tema || Invitado" → show label
    if (parts.isNotEmpty) return parts[0];
    return _getFullTitle();
  }

  /// Título del episodio.
  /// Formato 3 partes: show || tema || invitado → tema.
  /// Formato 2 partes: tema || invitado → tema.
  String _getVideoTitle() {
    final parts = _titleParts();
    if (parts.length >= 3) return parts[1];
    if (parts.length == 2) return parts[0];
    return _getFullTitle();
  }

  /// Invitado / guest.
  String? _getGuestName() {
    final parts = _titleParts();
    if (parts.length >= 3) return parts[2];
    if (parts.length == 2) return parts[1];
    return null;
  }

  Widget _buildMetaColumn({bool denser = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEpisodeHeader(),
        SizedBox(height: denser ? 16 : 20),
        _buildEpisodeDescription(),
        SizedBox(height: denser ? 16 : 20),
        _buildShareButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);
    final hPad = Responsive.horizontalPadding(context);
    final bottomPad = MediaQuery.of(context).padding.bottom + 24;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(
        title: _getAppBarTitle(),
        showBackButton: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: wide
                ? Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, bottomPad),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildVideoPlayer(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            child: _buildMetaColumn(denser: true),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideoPlayer(),
                        const SizedBox(height: 16),
                        _buildMetaColumn(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final videoId = _currentYouTubeVideo?.videoId ?? widget.youtubeVideo?.videoId;
    if (videoId == null || videoId.isEmpty || _controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: BrandColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.12),
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: BrandColors.grayDark,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'Video no disponible',
                  style: TextStyle(
                    color: BrandColors.grayMedium,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
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
            onReady: () {},
            onEnded: (_) {},
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () async {
                AppHaptics.light();
                if (_controller != null) {
                  _savedPosition = _controller!.value.position;
                }
                final result = await Navigator.of(context).push<Duration?>(
                  MaterialPageRoute(
                    builder: (context) => FullEpisodeScreen(
                      episode: _currentEpisode ?? widget.episode,
                      youtubeVideo:
                          _currentYouTubeVideo ?? widget.youtubeVideo,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fullscreen_rounded,
                  color: BrandColors.primaryWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeHeader() {
    final title = _getVideoTitle();
    final guest = _getGuestName();
    final publishedAt = _currentYouTubeVideo?.publishedAt ??
        widget.youtubeVideo?.publishedAt ??
        _currentEpisode?.publishedDate ??
        widget.episode?.publishedDate;
    final duration = _currentEpisode?.duration ?? widget.episode?.duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: BrandColors.primaryWhite,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            height: 1.3,
            letterSpacing: -0.2,
          ),
        ),
        if (guest != null) ...[
          const SizedBox(height: 8),
          Text(
            guest,
            style: const TextStyle(
              color: BrandColors.primaryOrange,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (publishedAt != null || (duration != null && duration.isNotEmpty)) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (publishedAt != null)
                _metaChip(
                  icon: Icons.calendar_today_rounded,
                  label: _formatDate(publishedAt),
                ),
              if (duration != null && duration.isNotEmpty && duration != '0:00')
                _metaChip(
                  icon: Icons.schedule_rounded,
                  label: duration,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: BrandColors.primaryOrange, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeDescription() {
    final description = _currentYouTubeVideo?.description ??
        widget.youtubeVideo?.description ??
        _currentEpisode?.description ??
        widget.episode?.description ??
        'Sin descripción disponible.';
    final canExpand = description.length > 220;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            color: BrandColors.primaryWhite,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Text(
            description,
            maxLines: _descriptionExpanded || !canExpand ? null : 5,
            overflow: _descriptionExpanded || !canExpand
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: TextStyle(
              color: BrandColors.grayLight.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),
        if (canExpand) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: AppHaptics.wrap(() {
              setState(() => _descriptionExpanded = !_descriptionExpanded);
            }),
            child: Text(
              _descriptionExpanded ? 'Ver menos' : 'Ver más',
              style: const TextStyle(
                color: BrandColors.primaryOrange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShareButton() {
    return Builder(
      builder: (ctx) => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => _shareEpisode(ctx),
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text(
            'Compartir episodio',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: BrandColors.primaryOrange,
            side: BorderSide(
              color: BrandColors.primaryOrange.withValues(alpha: 0.45),
            ),
            backgroundColor:
                BrandColors.primaryOrange.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _shareEpisode(BuildContext context) async {
    final episodeTitle = _getVideoTitle();
    final appBarTitle = _getAppBarTitle();
    final videoId = _currentEpisode?.youtubeVideoId ??
        _currentYouTubeVideo?.videoId ??
        widget.episode?.youtubeVideoId ??
        widget.youtubeVideo?.videoId ??
        '';

    String guest = _getGuestName() ?? '';
    if (guest.isEmpty) guest = episodeTitle;

    final youtubeUrl = videoId.isNotEmpty
        ? 'https://www.youtube.com/watch?v=$videoId'
        : '';

    final buffer = StringBuffer();
    buffer.writeln('Descubre el episodio "$appBarTitle"${guest.isNotEmpty ? ' con $guest' : ''}');
    buffer.writeln();
    buffer.writeln('Descarga DevLokos y accede a más episodios:');
    buffer.writeln(EnvironmentConfig.onelinkUrl);
    if (youtubeUrl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Ver en YouTube:');
      buffer.write(youtubeUrl);
    }
    var shareText = buffer.toString().trim();
    if (shareText.isEmpty) {
      shareText = 'Episodio de DevLokos\n\nDescarga la app: ${EnvironmentConfig.onelinkUrl}';
    }
    try {
      Rect sharePositionOrigin = const Rect.fromLTWH(0, 0, 1, 1);
      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final pos = box.localToGlobal(Offset.zero);
          sharePositionOrigin = Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
        } else {
          final size = MediaQuery.of(context).size;
          sharePositionOrigin = Rect.fromLTWH(size.width / 2 - 50, size.height / 2 - 50, 100, 100);
        }
      }
      await Share.share(
        shareText,
        sharePositionOrigin: sharePositionOrigin,
      );
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