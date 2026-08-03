import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tutorial.dart';
import '../utils/brand_colors.dart';
import 'youtube_video_card.dart' show highQualityThumb;

class TutorialCard extends StatelessWidget {
  final Tutorial tutorial;
  final VoidCallback onTap;
  final bool compact;

  const TutorialCard({
    super.key,
    required this.tutorial,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final thumbH = compact ? 140.0 : 160.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        enableFeedback: false,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
              children: [
                SizedBox(
                  width: double.infinity,
                  height: thumbH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: highQualityThumb(tutorial.thumbnailUrl),
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: BrandColors.grayDark),
                        errorWidget: (_, __, ___) => Container(
                          color: BrandColors.grayDark,
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: BrandColors.primaryOrange,
                            size: 36,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BrandColors.primaryOrange.withValues(
                              alpha: 0.92,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutorial.title,
                        style: const TextStyle(
                          color: BrandColors.primaryWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: BrandColors.grayMedium,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tutorial.formattedPublishedAt,
                            style: const TextStyle(
                              color: BrandColors.grayMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
