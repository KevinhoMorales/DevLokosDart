import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/academy/academy_bloc_exports.dart';
import '../../constants/learning_paths.dart';
import '../../repository/academy_repository.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/course_card.dart';
import '../../models/course.dart';

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

  final List<String> _difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  List<String> _availableLearningPaths = [];

  @override
  bool get wantKeepAlive => true;

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
        _availableLearningPaths = paths.isNotEmpty
            ? paths
            : LearningPaths.allPaths;
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
      appBar: const CustomAppBar(title: ''),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: SafeArea(
          child: BlocBuilder<AcademyBloc, AcademyState>(
            buildWhen: (prev, curr) =>
                prev.runtimeType != curr.runtimeType ||
                (curr is AcademyLoaded && prev is AcademyLoaded &&
                    curr.courses.length != prev.courses.length),
            builder: (context, state) {
              final hasContent = state is AcademyLoaded && state.courses.isNotEmpty;
              return Column(
                children: [
                  if (hasContent) ...[
                    _buildSearchBar(),
                    _buildFilters(),
                  ],
                  Expanded(child: _buildContent()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      child: SearchBarWidget(
        controller: _searchController,
        hintText: 'Buscar cursos...',
        onChanged: (value) {
          context.read<AcademyBloc>().add(SearchCourses(value.trim()));
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Ruta de aprendizaje',
              value: _selectedLearningPath,
              options: _availableLearningPaths,
              onSelected: (value) {
                setState(() {
                  _selectedLearningPath = value;
                });
                context.read<AcademyBloc>().add(
                      FilterCoursesByLearningPath(value),
                    );
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Dificultad',
              value: _selectedDifficulty,
              options: _difficulties,
              onSelected: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
                context.read<AcademyBloc>().add(
                      FilterCoursesByDifficulty(value),
                    );
              },
            ),
            if (_selectedLearningPath != null || _selectedDifficulty != null) ...[
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Limpiar'),
                onPressed: () {
                  setState(() {
                    _selectedLearningPath = null;
                    _selectedDifficulty = null;
                  });
                  context.read<AcademyBloc>().add(const ClearFilters());
                },
                backgroundColor: BrandColors.cardBackground,
                labelStyle: const TextStyle(color: BrandColors.primaryWhite),
                side: const BorderSide(color: BrandColors.primaryOrange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null ? BrandColors.primaryOrange.withOpacity(0.2) : BrandColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null ? BrandColors.primaryOrange : BrandColors.grayMedium,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                color: value != null ? BrandColors.primaryOrange : BrandColors.primaryWhite,
                fontSize: 12,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: value != null ? BrandColors.primaryOrange : BrandColors.grayMedium,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onSelected: onSelected,
    );
  }

  Widget _buildContent() {
    return BlocBuilder<AcademyBloc, AcademyState>(
      builder: (context, state) {
        if (state is AcademyLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
            ),
          );
        }

        // Mostrar empty state para errores de índice o cuando no hay cursos
        if (state is AcademyError) {
          // Si hay cursos en caché, mostrarlos en lugar del error
          if (state.cachedCourses != null && state.cachedCourses!.isNotEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AcademyBloc>().add(const RefreshCourses());
              },
              color: BrandColors.primaryOrange,
              child: ListView.builder(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 100,
              ),
              itemCount: state.cachedCourses!.length,
              itemBuilder: (context, index) {
                final course = state.cachedCourses![index];
                return CourseCard(
                  course: course,
                  onTap: () => _onCourseTap(course),
                );
              },
            ),
            );
          }

          return _buildRefreshableContent(
            child: _buildEmptyStateTutorialsStyle(
              icon: Icons.school_outlined,
              title: 'Academia próximamente',
              subtitle: 'Estamos preparando cursos para ti. Cuando agreguemos contenido, verás los cursos aquí.',
              showRetry: false,
            ),
          );
        }

        if (state is AcademyLoaded) {
          final courses = state.filteredCourses;

          if (courses.isEmpty) {
            return _buildRefreshableContent(
              child: _buildEmptyStateTutorialsStyle(
                icon: Icons.search_off,
                title: 'No se encontraron cursos',
                subtitle: 'Intenta con otros filtros o términos de búsqueda',
                showRetry: false,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AcademyBloc>().add(const RefreshCourses());
            },
            color: BrandColors.primaryOrange,
            child: ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
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

        // Estado inicial - mostrar empty state (igual que Tutoriales)
        return _buildRefreshableContent(
          child: _buildEmptyStateTutorialsStyle(
            icon: Icons.playlist_add_outlined,
            title: 'Academia próximamente',
            subtitle: 'Estamos preparando cursos para ti. Cuando agreguemos contenido, verás los cursos aquí.',
            showRetry: false,
          ),
        );
      },
    );
  }

  Widget _buildRefreshableContent({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AcademyBloc>().add(const RefreshCourses());
      },
      color: BrandColors.primaryOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Empty state con estilo de Eventos (icono circular, tipografía consistente)
  Widget _buildEmptyStateTutorialsStyle({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
    VoidCallback? onRetry,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: BrandColors.primaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: BrandColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: BrandColors.primaryWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: BrandColors.grayMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18, color: BrandColors.primaryOrange),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: BrandColors.primaryOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onCourseTap(Course course) {
    context.push('/course/${course.id}', extra: {'course': course});
  }
}
