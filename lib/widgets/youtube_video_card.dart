import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/youtube_video.dart';
import '../utils/brand_colors.dart';

class YouTubeVideoCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback? onTap;
  final bool showChannelTitle;

  const YouTubeVideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.showChannelTitle = true,
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 120,
            child: CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 120,
                color: BrandColors.grayDark,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.primaryOrange,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 120,
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

  Widget _buildMetadata() {
    return Row(
      children: [
        if (showChannelTitle) ...[
          Expanded(
            child: Text(
              video.channelTitle,
              style: const TextStyle(
                fontSize: 12,
                color: BrandColors.grayMedium,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          video.formattedPublishedAt,
          style: const TextStyle(
            fontSize: 10,
            color: BrandColors.grayLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      video.description,
      style: const TextStyle(
        fontSize: 13,
        color: BrandColors.grayMedium,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
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
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
          imageUrl: video.thumbnailUrl,
          width: 80,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 80,
            height: 60,
            color: BrandColors.grayDark,
            child: const Center(
              child: CircularProgressIndicator(
                color: BrandColors.primaryOrange,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 80,
            height: 60,
            color: BrandColors.grayDark,
            child: const Icon(
              Icons.error_outline,
              color: BrandColors.grayMedium,
            ),
          ),
        ),
      ),
      title: Text(
        video.title,
        style: const TextStyle(
          color: BrandColors.primaryWhite,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            video.channelTitle,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            video.formattedPublishedAt,
            style: const TextStyle(
              color: BrandColors.grayLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.play_circle_outline,
        color: BrandColors.primaryOrange,
        size: 28,
      ),
      onTap: onTap ?? () => _launchYouTubeVideo(context),
      ),
    );
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
