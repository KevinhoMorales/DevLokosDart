import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/episode.dart';
import '../../models/youtube_video.dart';
import '../../utils/brand_colors.dart';

class FullEpisodeScreen extends StatefulWidget {
  final Episode? episode;
  final YouTubeVideo? youtubeVideo;
  final Duration? initialPosition;

  const FullEpisodeScreen({
    super.key,
    this.episode,
    this.youtubeVideo,
    this.initialPosition,
  });

  @override
  State<FullEpisodeScreen> createState() => _FullEpisodeScreenState();
}

class _FullEpisodeScreenState extends State<FullEpisodeScreen> with WidgetsBindingObserver {
  YoutubePlayerController? _controller;
  Duration? _currentPosition;

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
      
      // Si hay una posición inicial, configurarla después de que el reproductor esté listo
      if (widget.initialPosition != null) {
        print('🎯 Posición inicial configurada: ${widget.initialPosition!.inSeconds} segundos');
        _currentPosition = widget.initialPosition;
      }
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
    // Guardar la posición actual del video antes de salir
    if (_controller != null) {
      _currentPosition = _controller!.value.position;
      print('💾 Posición guardada: ${_currentPosition?.inSeconds} segundos');
    }
    
    // Restaurar barras del sistema
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Restaurar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Regresar a la pantalla anterior con la posición guardada
    Navigator.of(context).pop(_currentPosition);
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
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: BrandColors.primaryOrange,
                      progressColors: const ProgressBarColors(
                        playedColor: BrandColors.primaryOrange,
                        handleColor: BrandColors.primaryOrange,
                      ),
                      onReady: () {
                        print('✅ Reproductor de pantalla completa listo');
                        // Si hay una posición inicial, buscarla
                        if (widget.initialPosition != null && _controller != null) {
                          print('🎯 Buscando a posición inicial: ${widget.initialPosition!.inSeconds} segundos');
                          _controller!.seekTo(widget.initialPosition!);
                        }
                      },
                      onEnded: (data) {
                        print('🏁 Video terminado en pantalla completa');
                        _exitFullScreen();
                      },
                    ),
                    // Botón de salir de pantalla completa
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

            // Botón de cerrar en la esquina superior izquierda
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
