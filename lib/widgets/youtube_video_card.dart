import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/youtube_video.dart';
import '../utils/brand_colors.dart';

class YouTubeVideoCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback? onTap;
  final bool showChannelTitle;
  final double? thumbnailHeight;

  const YouTubeVideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.showChannelTitle = true,
    this.thumbnailHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = thumbnailHeight != null && thumbnailHeight! < 140;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _launchYouTubeVideo(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                spreadRadius: 0,
              ),
              BoxShadow(
                color: BrandColors.primaryOrange.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 2),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThumbnail(),
                Padding(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  child: _buildTitle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final height = thumbnailHeight ?? 180;
    final playSize = height < 140 ? 48.0 : 56.0;
    
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: height,
          child: CachedNetworkImage(
            imageUrl: _getHighQualityThumbnail(video.thumbnailUrl),
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            placeholder: (context, url) => Container(
              height: height,
              color: BrandColors.grayDark.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: BrandColors.primaryOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: height,
              color: BrandColors.grayDark.withOpacity(0.5),
              child: Icon(
                Icons.play_circle_outline,
                color: BrandColors.primaryOrange.withOpacity(0.5),
                size: 48,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: SizedBox(
              width: playSize + 16,
              height: playSize + 16,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.primaryOrange.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      BrandColors.primaryOrange,
                      BrandColors.orangeLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: playSize,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              video.formattedPublishedAt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      video.title,
      style: TextStyle(
        fontSize: thumbnailHeight != null && thumbnailHeight! < 140 ? 13 : 15,
        fontWeight: FontWeight.w600,
        color: BrandColors.primaryWhite,
        height: 1.35,
        letterSpacing: 0.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }


  String _getHighQualityThumbnail(String thumbnailUrl) {
    // YouTube proporciona diferentes calidades de thumbnail
    // Si es un thumbnail de YouTube, intentar obtener la versión de alta calidad
    if (thumbnailUrl.contains('ytimg.com') || thumbnailUrl.contains('youtube.com')) {
      // Reemplazar diferentes tamaños de thumbnail con la versión de alta calidad
      final highQualityUrl = thumbnailUrl
          .replaceAll('/default.jpg', '/maxresdefault.jpg')
          .replaceAll('/mqdefault.jpg', '/maxresdefault.jpg')
          .replaceAll('/hqdefault.jpg', '/maxresdefault.jpg')
          .replaceAll('/sddefault.jpg', '/maxresdefault.jpg');
      
      return highQualityUrl;
    }
    return thumbnailUrl;
  }

  void _launchYouTubeVideo(BuildContext context) {
    // TODO: Implementar navegación al video o reproducción
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reproduciendo: ${video.title}'),
        backgroundColor: BrandColors.primaryOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class YouTubeVideoListTile extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback? onTap;

  const YouTubeVideoListTile({
    super.key,
    required this.video,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap ?? () => _launchYouTubeVideo(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail mejorado
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BrandColors.grayDark,
                  ),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: _getHighQualityThumbnail(video.thumbnailUrl),
                        width: 100,
                        height: 80,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 80,
                          color: BrandColors.grayDark,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: BrandColors.primaryOrange,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 80,
                          color: BrandColors.grayDark,
                          child: const Icon(
                            Icons.error_outline,
                            color: BrandColors.grayMedium,
                            size: 32,
                          ),
                        ),
                      ),
                      // Play button overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.channelTitle,
                      style: const TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.formattedPublishedAt,
                      style: const TextStyle(
                        color: BrandColors.grayLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play icon
              const Icon(
                Icons.play_circle_outline,
                color: BrandColors.primaryOrange,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHighQualityThumbnail(String thumbnailUrl) {
    // YouTube proporciona diferentes calidades de thumbnail
    // Si es un thumbnail de YouTube, intentar obtener la versión de alta calidad
    if (thumbnailUrl.contains('ytimg.com') || thumbnailUrl.contains('youtube.com')) {
      // Reemplazar diferentes tamaños de thumbnail con la versión de alta calidad
      final highQualityUrl = thumbnailUrl
          .replaceAll('/default.jpg', '/maxresdefault.jpg')
          .replaceAll('/mqdefault.jpg', '/maxresdefault.jpg')
          .replaceAll('/hqdefault.jpg', '/maxresdefault.jpg')
          .replaceAll('/sddefault.jpg', '/maxresdefault.jpg');
      
      return highQualityUrl;
    }
    return thumbnailUrl;
  }

  void _launchYouTubeVideo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reproduciendo: ${video.title}'),
        backgroundColor: BrandColors.primaryOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
