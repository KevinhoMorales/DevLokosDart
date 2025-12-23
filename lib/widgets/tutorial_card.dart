import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tutorial.dart';
import '../utils/brand_colors.dart';

class TutorialCard extends StatelessWidget {
  final Tutorial tutorial;
  final VoidCallback onTap;

  const TutorialCard({
    super.key,
    required this.tutorial,
    required this.onTap,
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
        onTap: onTap,
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
                  // Title
                  _buildTitle(),
                  const SizedBox(height: 8),
                  
                  // Meta info (Level, Duration)
                  _buildMetaInfo(),
                  const SizedBox(height: 8),
                  
                  // Tech stack tags
                  _buildTechStackTags(),
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
            height: 180,
            child: CachedNetworkImage(
              imageUrl: tutorial.thumbnailUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180,
                color: BrandColors.grayDark,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.primaryOrange,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180,
                color: BrandColors.grayDark,
                child: const Icon(
                  Icons.error_outline,
                  color: BrandColors.grayMedium,
                  size: 48,
                ),
              ),
            ),
          ),
          // Play icon overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: BrandColors.primaryOrange,
                  size: 64,
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
      tutorial.title,
      style: const TextStyle(
        color: BrandColors.primaryWhite,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getLevelColor(tutorial.level).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getLevelColor(tutorial.level),
              width: 1,
            ),
          ),
          child: Text(
            tutorial.level,
            style: TextStyle(
              color: _getLevelColor(tutorial.level),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Duration
        Row(
          children: [
            const Icon(
              Icons.access_time,
              color: BrandColors.grayMedium,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              tutorial.formattedDuration,
              style: const TextStyle(
                color: BrandColors.grayMedium,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechStackTags() {
    if (tutorial.techStack.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tutorial.techStack.take(3).map((tech) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: BrandColors.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: BrandColors.primaryOrange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            tech,
            style: const TextStyle(
              color: BrandColors.primaryOrange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return BrandColors.success;
      case 'intermediate':
        return BrandColors.warning;
      case 'advanced':
        return BrandColors.error;
      default:
        return BrandColors.grayMedium;
    }
  }
}

