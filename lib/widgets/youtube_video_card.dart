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
        onTap: onTap,
        enableFeedback: false,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: BrandColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.15),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThumbnail(isCompact),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 12 : 14,
                    isCompact ? 10 : 12,
                    isCompact ? 12 : 14,
                    isCompact ? 12 : 14,
                  ),
                  child: Text(
                    video.title,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.primaryWhite,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isCompact) {
    final height = thumbnailHeight ?? 168;
    final playSize = isCompact ? 28.0 : 34.0;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: height,
          child: CachedNetworkImage(
            imageUrl: highQualityThumb(video.thumbnailUrl),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            placeholder: (_, __) => Container(
              color: BrandColors.grayDark.withValues(alpha: 0.5),
            ),
            errorWidget: (_, __, ___) => Container(
              color: BrandColors.grayDark.withValues(alpha: 0.5),
              child: Icon(
                Icons.play_circle_outline,
                color: BrandColors.primaryOrange.withValues(alpha: 0.5),
                size: 36,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              width: playSize + 10,
              height: playSize + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.primaryOrange.withValues(alpha: 0.92),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: playSize,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              video.formattedPublishedAt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tile denso para listas (Episodios / resultados).
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        enableFeedback: false,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BrandColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 112,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: highQualityThumb(video.thumbnailUrl),
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: BrandColors.grayDark),
                        errorWidget: (_, __, ___) => Container(
                          color: BrandColors.grayDark,
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: BrandColors.primaryOrange,
                            size: 28,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BrandColors.primaryOrange.withValues(
                              alpha: 0.9,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.formattedPublishedAt,
                      style: const TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String highQualityThumb(String thumbnailUrl) {
  if (thumbnailUrl.contains('ytimg.com') ||
      thumbnailUrl.contains('youtube.com')) {
    return thumbnailUrl
        .replaceAll('/default.jpg', '/hqdefault.jpg')
        .replaceAll('/mqdefault.jpg', '/hqdefault.jpg')
        .replaceAll('/sddefault.jpg', '/hqdefault.jpg');
  }
  return thumbnailUrl;
}
