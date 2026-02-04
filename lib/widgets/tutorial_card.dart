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
                  // Fecha de publicación (desde YouTube)
                  _buildPublishedAt(),
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

  Widget _buildPublishedAt() {
    return Row(
      children: [
        const Icon(
          Icons.schedule,
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
    );
  }
}


