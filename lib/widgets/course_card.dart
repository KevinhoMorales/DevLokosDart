import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/course.dart';
import '../utils/brand_colors.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
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
            if (course.thumbnailUrl != null) _buildThumbnail(),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildTitle(),
                  const SizedBox(height: 12),
                  
                  // Meta info
                  _buildMetaInfo(),
                  const SizedBox(height: 12),
                  
                  // Learning paths
                  if (course.learningPaths.isNotEmpty) _buildLearningPaths(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _thumbnailHeight = 120;

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: _thumbnailHeight,
        child: CachedNetworkImage(
          imageUrl: course.thumbnailUrl!,
          width: double.infinity,
          height: _thumbnailHeight,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: _thumbnailHeight,
            color: BrandColors.grayDark,
            child: const Center(
              child: CircularProgressIndicator(
                color: BrandColors.primaryOrange,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: _thumbnailHeight,
            color: BrandColors.grayDark,
            child: const Icon(
              Icons.school,
              color: BrandColors.grayMedium,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      course.title,
      style: const TextStyle(
        color: BrandColors.primaryWhite,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        // Difficulty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDifficultyColor(course.difficulty).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getDifficultyColor(course.difficulty),
              width: 1,
            ),
          ),
          child: Text(
            course.difficulty,
            style: TextStyle(
              color: _getDifficultyColor(course.difficulty),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (course.duration > 0) ...[
          const SizedBox(width: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: BrandColors.grayMedium,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                course.formattedDuration,
                style: const TextStyle(
                  color: BrandColors.grayMedium,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
        const Spacer(),
        // Modules count (solo si hay módulos)
        if (course.modules.isNotEmpty)
          Row(
            children: [
              const Icon(
                Icons.menu_book,
                color: BrandColors.grayMedium,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${course.modules.length} módulos',
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

  Widget _buildLearningPaths() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: course.learningPaths.map((path) {
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
            path,
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
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


