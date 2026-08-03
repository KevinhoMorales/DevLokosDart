import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/learning_paths.dart';
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
                if (course.thumbnailUrl != null &&
                    course.thumbnailUrl!.isNotEmpty)
                  _buildThumbnail()
                else
                  _buildPlaceholderThumb(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: BrandColors.primaryWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      _buildMetaInfo(),
                      if (course.learningPaths.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildLearningPaths(),
                      ],
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

  Widget _buildThumbnail() {
    return SizedBox(
      width: double.infinity,
      height: 128,
      child: CachedNetworkImage(
        imageUrl: course.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: BrandColors.grayDark),
        errorWidget: (_, __, ___) => _buildPlaceholderThumb(),
      ),
    );
  }

  Widget _buildPlaceholderThumb() {
    return Container(
      width: double.infinity,
      height: 96,
      color: BrandColors.blackLight,
      child: const Center(
        child: Icon(
          Icons.school_rounded,
          color: BrandColors.primaryOrange,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildMetaInfo() {
    final difficultyLabel = _difficultyLabel(course.difficulty);
    final difficultyColor = _difficultyColor(course.difficulty);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: difficultyColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: difficultyColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            difficultyLabel,
            style: TextStyle(
              color: difficultyColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (course.duration > 0) ...[
          const SizedBox(width: 10),
          const Icon(
            Icons.access_time_rounded,
            color: BrandColors.grayMedium,
            size: 14,
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
        if (course.modules.isNotEmpty) ...[
          const Spacer(),
          Text(
            '${course.modules.length} módulos',
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLearningPaths() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: course.learningPaths.take(3).map((path) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: BrandColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            LearningPaths.displayLabel(path),
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

  String _difficultyLabel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'principiante':
        return 'Principiante';
      case 'intermediate':
      case 'intermedio':
        return 'Intermedio';
      case 'advanced':
      case 'avanzado':
        return 'Avanzado';
      default:
        return difficulty.isEmpty ? 'General' : difficulty;
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'principiante':
        return BrandColors.success;
      case 'intermediate':
      case 'intermedio':
        return BrandColors.warning;
      case 'advanced':
      case 'avanzado':
        return BrandColors.error;
      default:
        return BrandColors.grayMedium;
    }
  }
}
