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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      color: BrandColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: BrandColors.primaryOrange,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap ?? () => _launchYouTubeVideo(context),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            _buildThumbnail(),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title only
                  _buildTitle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final height = thumbnailHeight ?? 160; // Usar altura personalizada o 160 por defecto
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
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
                color: BrandColors.grayDark,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.primaryOrange,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: height,
                color: BrandColors.grayDark,
                child: const Icon(
                  Icons.error_outline,
                  color: BrandColors.grayMedium,
                  size: 48,
                ),
              ),
            ),
          ),
          
          // Play button overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
          
          // Duration badge (si estuviera disponible)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                video.formattedPublishedAt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      video.title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: BrandColors.primaryWhite,
        height: 1.2,
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
