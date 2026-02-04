import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course.dart';
import '../../repository/academy_repository.dart';
import '../../services/analytics_service.dart';
import '../../constants/app_constants.dart';
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
      learningPaths: course.learningPaths.isNotEmpty ? course.learningPaths : null,
    );
  }

  Future<void> _loadCourse() async {
    final course = await AcademyRepositoryImpl().getCourseById(widget.courseId);
    if (mounted) {
      setState(() {
        _course = course;
        _isLoading = false;
        if (course == null) {
          _error = 'Curso no encontrado';
        } else if (!course.isPublished) {
          _error = 'Curso no disponible';
          _course = null; // No mostrar cursos no publicados
        }
      });
      if (course != null && course.isPublished) {
        _logCourseViewed(course);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(title: 'Curso', showBackButton: true),
        body: const Center(
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
    // No mostrar cursos no publicados (por si llegaron por deep link)
    if (!course.isPublished) {
      return Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(title: 'Curso', showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Curso no disponible',
              style: const TextStyle(color: BrandColors.grayMedium),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(
        title: course.title.length > 30
            ? '${course.title.substring(0, 27)}...'
            : course.title,
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroImage(course),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasMetaContent(course)) ...[
                    _buildMetaSection(course),
                    const SizedBox(height: 24),
                  ],
                    if (course.description.isNotEmpty) ...[
                      _buildSectionTitle('Descripción'),
                      const SizedBox(height: 8),
                      Text(
                        course.description,
                        style: const TextStyle(
                          color: BrandColors.grayLight,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (course.learningObjectives.isNotEmpty) ...[
                      _buildSectionTitle('Qué aprenderás'),
                      const SizedBox(height: 8),
                      ...course.learningObjectives.map(
                        (obj) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: BrandColors.primaryOrange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  obj,
                                  style: const TextStyle(
                                    color: BrandColors.grayLight,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    GradientButton(
                      onPressed: _openAcademyWhatsApp,
                      text: 'Inscribirme por WhatsApp',
                      icon: Icons.chat,
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

  Widget _buildHeroImage(Course course) {
    if (course.thumbnailUrl == null || course.thumbnailUrl!.isEmpty) {
      return Container(
        height: 200,
        color: BrandColors.blackLight,
        child: Center(
          child: Icon(
            Icons.school_rounded,
            size: 80,
            color: BrandColors.grayMedium.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: course.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: BrandColors.blackLight,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: BrandColors.blackLight,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: BrandColors.grayMedium.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaSection(Course course) {
    final hasDifficulty = course.difficulty.isNotEmpty;
    final hasDuration = course.duration > 0;
    final hasProfessor = course.professor != null && course.professor!.isNotEmpty;
    final hasPaths = course.learningPaths.isNotEmpty;

    if (!hasDifficulty && !hasDuration && !hasProfessor && !hasPaths) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          if (hasDifficulty || hasDuration)
            Row(
              children: [
                if (hasDifficulty) ...[
                  Icon(Icons.school, size: 20, color: BrandColors.primaryOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      course.difficulty,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
                if (hasDuration)
                  Text(
                    course.formattedDuration,
                    style: TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          if (hasProfessor) ...[
            if (hasDifficulty || hasDuration) const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: BrandColors.primaryOrange),
                const SizedBox(width: 12),
                Text(
                  course.professor!,
                  style: const TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
          if (hasPaths) ...[
            if (hasDifficulty || hasDuration || hasProfessor) const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: course.learningPaths.map((path) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    path,
                    style: const TextStyle(
                      color: BrandColors.primaryOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  bool _hasMetaContent(Course course) {
    return course.difficulty.isNotEmpty ||
        course.duration > 0 ||
        (course.professor != null && course.professor!.isNotEmpty) ||
        course.learningPaths.isNotEmpty;
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: BrandColors.primaryOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: BrandColors.primaryOrange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    } catch (e) {
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
