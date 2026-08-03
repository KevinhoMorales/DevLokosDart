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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: BrandColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: BrandColors.primaryOrange.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontSize: 17,
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
                    const SizedBox(height: 12),
                    const Text(
                      'Ver curso',
                      style: TextStyle(
                        color: BrandColors.primaryOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _buildCover() {
    return SizedBox(
      width: double.infinity,
      height: 148,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: course.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: BrandColors.grayDark),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          if (course.modules.isNotEmpty)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BrandColors.primaryBlack.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BrandColors.primaryOrange.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${course.modules.length} módulos',
                  style: const TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: BrandColors.blackLight,
      child: const Center(
        child: Icon(
          Icons.school_rounded,
          color: BrandColors.primaryOrange,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildMetaInfo() {
    final difficultyLabel = _difficultyLabel(course.difficulty);
    final difficultyColor = _difficultyColor(course.difficulty);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: difficultyColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: difficultyColor.withValues(alpha: 0.45)),
          ),
          child: Text(
            difficultyLabel,
            style: TextStyle(
              color: difficultyColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (course.duration > 0)
          Text(
            course.formattedDuration,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildLearningPaths() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: course.learningPaths.take(3).map((path) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: BrandColors.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            LearningPaths.displayLabel(path),
            style: const TextStyle(
              color: BrandColors.primaryOrange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
