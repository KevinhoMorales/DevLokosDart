import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/academy/academy_bloc_exports.dart';
import '../../constants/app_constants.dart';
import '../../constants/learning_paths.dart';
import '../../models/course.dart';
import '../../repository/academy_repository.dart';
import '../../utils/brand_colors.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/content_skeleton.dart';
import '../../widgets/course_card.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/section_header.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLearningPath;
  String? _selectedDifficulty;

  static const _difficulties = [
    ('Beginner', 'Principiante'),
    ('Intermediate', 'Intermedio'),
    ('Advanced', 'Avanzado'),
  ];

  List<String> _availableLearningPaths = [];

  @override
  bool get wantKeepAlive => true;

  bool get _hasActiveFilters =>
      _selectedLearningPath != null ||
      _selectedDifficulty != null ||
      _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadLearningPaths();
  }

  Future<void> _loadLearningPaths() async {
    final repository = AcademyRepositoryImpl();
    final paths = await repository.getAllLearningPaths();
    if (mounted) {
      setState(() {
        _availableLearningPaths =
            paths.isNotEmpty ? paths : LearningPaths.allPaths;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: const CustomAppBar(title: ''),
      body: SafeArea(
        child: BlocBuilder<AcademyBloc, AcademyState>(
          builder: (context, state) {
            final showFilters = state is AcademyLoaded &&
                (state.courses.isNotEmpty || _hasActiveFilters);

            return Column(
              children: [
                Padding(
                  padding: Responsive.searchBarPadding(context),
                  child: SearchBarWidget(
                    controller: _searchController,
                    hintText: 'Buscar cursos...',
                    onChanged: (value) {
                      context
                          .read<AcademyBloc>()
                          .add(SearchCourses(value.trim()));
                      setState(() {});
                    },
                  ),
                ),
                if (showFilters) _buildFilters(),
                Expanded(child: _buildContent(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Ruta',
              value: _selectedLearningPath,
              options: _availableLearningPaths,
              labels: {
                for (final p in _availableLearningPaths)
                  p: LearningPaths.displayLabel(p),
              },
              onSelected: (value) {
                setState(() => _selectedLearningPath = value);
                context
                    .read<AcademyBloc>()
                    .add(FilterCoursesByLearningPath(value));
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Dificultad',
              value: _selectedDifficulty,
              options: _difficulties.map((e) => e.$1).toList(),
              labels: {for (final e in _difficulties) e.$1: e.$2},
              onSelected: (value) {
                setState(() => _selectedDifficulty = value);
                context
                    .read<AcademyBloc>()
                    .add(FilterCoursesByDifficulty(value));
              },
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Limpiar'),
                onPressed: _clearFilters,
                backgroundColor: BrandColors.cardBackground,
                labelStyle: const TextStyle(
                  color: BrandColors.primaryWhite,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedLearningPath = null;
      _selectedDifficulty = null;
      _searchController.clear();
    });
    context.read<AcademyBloc>().add(const ClearFilters());
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<String> options,
    required Map<String, String> labels,
    required ValueChanged<String> onSelected,
  }) {
    final display = value != null ? (labels[value] ?? value) : label;
    return PopupMenuButton<String>(
      color: BrandColors.cardBackground,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null
              ? BrandColors.primaryOrange.withValues(alpha: 0.16)
              : BrandColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null
                ? BrandColors.primaryOrange.withValues(alpha: 0.7)
                : BrandColors.primaryOrange.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              display,
              style: TextStyle(
                color: value != null
                    ? BrandColors.primaryOrange
                    : BrandColors.primaryWhite,
                fontSize: 12,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: value != null
                  ? BrandColors.primaryOrange
                  : BrandColors.grayMedium,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem<String>(
              value: option,
              child: Text(
                labels[option] ?? option,
                style: const TextStyle(color: BrandColors.primaryWhite),
              ),
            ),
          )
          .toList(),
      onSelected: onSelected,
    );
  }

  Widget _buildContent(AcademyState state) {
    if (state is AcademyLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: ContentSkeleton.card(count: 3),
      );
    }

    if (state is AcademyError) {
      if (state.cachedCourses != null && state.cachedCourses!.isNotEmpty) {
        return _buildCourseList(state.cachedCourses!);
      }
      return AppErrorState(
        title: 'No pudimos cargar la Academia',
        message: state.message,
        onRetry: () =>
            context.read<AcademyBloc>().add(const RefreshCourses()),
      );
    }

    if (state is AcademyLoaded) {
      final courses = state.filteredCourses;
      final upcoming = state.upcomingCourses;
      final catalogEmpty = state.courses.isEmpty;

      if (courses.isEmpty) {
        return _buildRefreshable(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (catalogEmpty)
                AppEmptyState(
                  icon: Icons.school_outlined,
                  title: 'Academia próximamente',
                  subtitle:
                      'Estamos preparando cursos. Escríbenos y te avisamos.',
                  action: _whatsAppButton(),
                )
              else
                AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Sin resultados',
                  subtitle: 'Prueba otros filtros o limpia la búsqueda.',
                  showRetry: true,
                  retryLabel: 'Limpiar filtros',
                  onRetry: _clearFilters,
                ),
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: 'Próximamente',
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                ...upcoming.take(3).map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CourseCard(
                          course: c,
                          onTap: () => _onCourseTap(c),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<AcademyBloc>().add(const RefreshCourses());
        },
        color: BrandColors.primaryOrange,
        child: ListView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.of(context).padding.bottom + 100,
          ),
          children: [
            SectionHeader(
              title: 'Cursos',
              padding: EdgeInsets.zero,
              trailing: Text(
                '${courses.length}',
                style: const TextStyle(
                  color: BrandColors.grayMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...courses.map(
              (course) => CourseCard(
                course: course,
                onTap: () => _onCourseTap(course),
              ),
            ),
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Próximamente',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              ...upcoming.take(3).map(
                    (c) => CourseCard(
                      course: c,
                      onTap: () => _onCourseTap(c),
                    ),
                  ),
            ],
          ],
        ),
      );
    }

    return _buildRefreshable(
      child: AppEmptyState(
        icon: Icons.school_outlined,
        title: 'Academia próximamente',
        subtitle: 'Estamos preparando cursos para ti.',
        action: _whatsAppButton(),
      ),
    );
  }

  Widget _buildCourseList(List<Course> courses) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AcademyBloc>().add(const RefreshCourses());
      },
      color: BrandColors.primaryOrange,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return CourseCard(
            course: course,
            onTap: () => _onCourseTap(course),
          );
        },
      ),
    );
  }

  Widget _whatsAppButton() {
    return TextButton(
      onPressed: _openAcademyWhatsApp,
      child: const Text(
        'Consultar por WhatsApp',
        style: TextStyle(
          color: BrandColors.primaryOrange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openAcademyWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/${AppConstants.academyWhatsAppNumber}'
      '?text=${Uri.encodeComponent(AppConstants.academyWhatsAppMessage)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildRefreshable({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AcademyBloc>().add(const RefreshCourses());
      },
      color: BrandColors.primaryOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 220,
          ),
          child: child,
        ),
      ),
    );
  }

  void _onCourseTap(Course course) {
    context.push('/course/${course.id}', extra: {'course': course});
  }
}
