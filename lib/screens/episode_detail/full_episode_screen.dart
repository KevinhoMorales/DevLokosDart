import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../utils/brand_colors.dart';

class FullEpisodeScreen extends StatefulWidget {
  final Episode? episode;
  final YouTubeVideo? youtubeVideo;

  const FullEpisodeScreen({
    super.key,
    this.episode,
    this.youtubeVideo,
  });

  @override
  State<FullEpisodeScreen> createState() => _FullEpisodeScreenState();
}

class _FullEpisodeScreenState extends State<FullEpisodeScreen> with WidgetsBindingObserver {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _setLandscapeOrientation();
  }

  void _initializePlayer() {
    final videoId = widget.youtubeVideo?.videoId ?? '';
    
    if (videoId.isNotEmpty) {
              _controller = YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(
                  autoPlay: true,
                  mute: false,
                  isLive: false,
                  forceHD: true,
                  enableCaption: false,
                  hideControls: false,
                  showLiveFullscreenButton: false,
                  controlsVisibleAtStart: true,
                  disableDragSeek: false,
                  loop: false,
                  useHybridComposition: false,
                  hideThumbnail: true,
                ),
              );
    }
  }

  void _setLandscapeOrientation() {
    // Configurar orientación landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Ocultar barras del sistema de forma más simple
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    // Restaurar barras del sistema
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Restaurar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Regresar a la pantalla anterior
    Navigator.of(context).pop();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Mantener las barras del sistema ocultas
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    
    // Restaurar orientación y barras del sistema al salir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Reproductor de video que ocupa toda la pantalla
            if (_controller != null)
              Center(
                child: Stack(
                  children: [
                            YoutubePlayer(
                              controller: _controller!,
                              showVideoProgressIndicator: true, // Mostrar barra de progreso nativa
                              progressIndicatorColor: BrandColors.primaryOrange,
                              progressColors: const ProgressBarColors(
                                playedColor: BrandColors.primaryOrange,
                                handleColor: BrandColors.primaryOrange,
                              ),
                              onReady: () {
                                print('✅ Reproductor de pantalla completa listo');
                              },
                              onEnded: (data) {
                                print('🏁 Video terminado en pantalla completa');
                                _exitFullScreen();
                              },
                            ),
                            // Overlay solo en la esquina inferior derecha para cubrir el botón de pantalla completa
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IgnorePointer(
                                ignoring: false,
                                child: GestureDetector(
                                  onTap: () {
                                    // Interceptar toques solo en esta área
                                    print('Toque interceptado en área de pantalla completa');
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                    // Logo de DevLokos para cubrir el botón de pantalla completa
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _exitFullScreen,
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: BrandColors.primaryOrange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.fullscreen_exit,
                            color: BrandColors.primaryOrange,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
                ),
              ),

            // Botón de salir en la esquina superior izquierda
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _exitFullScreen,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Información del episodio en la esquina superior derecha
            if (widget.episode != null || widget.youtubeVideo != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getEpisodeTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      if (widget.youtubeVideo?.channelTitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.youtubeVideo!.channelTitle,
                          style: const TextStyle(
                            color: BrandColors.grayMedium,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  String _getEpisodeTitle() {
    final fullTitle = widget.youtubeVideo?.title ?? widget.episode?.title ?? 'Episodio';
    
    // Dividir por el primer ||
    final parts = fullTitle.split('||');
    if (parts.length > 1) {
      return parts[0].trim();
    }
    
    return fullTitle;
  }

}
