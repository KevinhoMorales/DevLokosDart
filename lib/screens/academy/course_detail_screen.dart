import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course.dart';
import '../../repository/academy_repository.dart';
import '../../services/analytics_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/learning_paths.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Course? course;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    if (_course == null) {
      _loadCourse();
    } else {
      _isLoading = false;
      _logCourseViewed(_course!);
    }
  }

  void _logCourseViewed(Course course) {
    if (!course.isPublished) return;
    AnalyticsService.logCourseViewed(
      courseId: course.id,
      courseTitle: course.title,
      level: course.difficulty,
      learningPaths:
          course.learningPaths.isNotEmpty ? course.learningPaths : null,
    );
  }

  Future<void> _loadCourse() async {
    final course = await AcademyRepositoryImpl().getCourseById(widget.courseId);
    if (!mounted) return;
    setState(() {
      _course = course;
      _isLoading = false;
      if (course == null) {
        _error = 'Curso no encontrado';
      } else if (!course.isPublished) {
        _error = 'Curso no disponible';
        _course = null;
      }
    });
    if (course != null && course.isPublished) {
      _logCourseViewed(course);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: CustomAppBar(title: 'Curso', showBackButton: true),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
          ),
        ),
      );
    }

    if (_course == null || _error != null) {
      return Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(title: 'Curso', showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _error ?? 'Curso no encontrado',
              style: const TextStyle(color: BrandColors.grayMedium),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final course = _course!;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(
        title: course.title.length > 28
            ? '${course.title.substring(0, 25)}...'
            : course.title,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCover(course: course),
                  const SizedBox(height: 20),
                  Text(
                    course.title,
                    style: const TextStyle(
                      color: BrandColors.primaryWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MetaCard(course: course),
                  if (course.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('Descripción'),
                    const SizedBox(height: 10),
                    Text(
                      course.description,
                      style: TextStyle(
                        color: BrandColors.primaryWhite.withValues(alpha: 0.88),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ],
                  if (course.learningObjectives.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('Qué aprenderás'),
                    const SizedBox(height: 12),
                    ...course.learningObjectives.map(
                      (obj) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: BrandColors.primaryOrange
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: BrandColors.primaryOrange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                obj,
                                style: TextStyle(
                                  color: BrandColors.primaryWhite
                                      .withValues(alpha: 0.85),
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (course.modules.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('Contenido del curso'),
                    const SizedBox(height: 12),
                    ...List.generate(course.modules.length, (i) {
                      final mod = course.modules[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: BrandColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: BrandColors.primaryOrange
                                .withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: BrandColors.primaryOrange
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: BrandColors.primaryOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mod.title.isNotEmpty
                                    ? mod.title
                                    : 'Módulo ${i + 1}',
                                style: const TextStyle(
                                  color: BrandColors.primaryWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 12),
            decoration: BoxDecoration(
              color: BrandColors.primaryBlack,
              border: Border(
                top: BorderSide(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.2),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: GradientButton(
              onPressed: AppHaptics.wrap(_openAcademyWhatsApp),
              text: 'Inscribirme por WhatsApp',
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAcademyWhatsApp() async {
    if (_course != null) {
      AnalyticsService.logAcademyWhatsAppClicked(courseTitle: _course!.title);
    }
    final message = _course != null
        ? 'Hola, me gustaría inscribirme en el curso "${_course!.title}" de la Academia DevLokos. ¿Cuáles son los pasos?'
        : AppConstants.academyWhatsAppMessage;
    final url = 'https://wa.me/${AppConstants.academyWhatsAppNumber}'
        '?text=${Uri.encodeComponent(message)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    }
  }
}

class _HeroCover extends StatelessWidget {
  final Course course;

  const _HeroCover({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: course.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: BrandColors.grayDark),
              errorWidget: (_, __, ___) => Container(
                color: BrandColors.blackLight,
                child: const Icon(
                  Icons.school_rounded,
                  color: BrandColors.primaryOrange,
                  size: 48,
                ),
              ),
            )
          else
            Container(
              color: BrandColors.blackLight,
              child: const Icon(
                Icons.school_rounded,
                color: BrandColors.primaryOrange,
                size: 48,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final Course course;

  const _MetaCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final hasDifficulty = course.difficulty.isNotEmpty;
    final hasDuration = course.duration > 0;
    final hasProfessor =
        course.professor != null && course.professor!.trim().isNotEmpty;
    final hasPaths = course.learningPaths.isNotEmpty;

    if (!hasDifficulty && !hasDuration && !hasProfessor && !hasPaths) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDifficulty || hasDuration)
            Row(
              children: [
                if (hasDifficulty)
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 16,
                        color: BrandColors.primaryWhite,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _difficultyLabel(course.difficulty),
                        style: const TextStyle(
                          color: BrandColors.primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (hasDifficulty && hasDuration) const Spacer(),
                if (hasDuration)
                  Text(
                    course.formattedDuration,
                    style: const TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          if (hasProfessor) ...[
            if (hasDifficulty || hasDuration) const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: BrandColors.primaryWhite,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    course.professor!.trim(),
                    style: const TextStyle(
                      color: BrandColors.primaryWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasPaths) ...[
            if (hasDifficulty || hasDuration || hasProfessor)
              const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: course.learningPaths.map((path) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
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

}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: BrandColors.primaryOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: BrandColors.primaryOrange,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
