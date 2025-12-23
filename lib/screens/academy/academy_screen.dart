import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/academy/academy_bloc_exports.dart';
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
  bool _showUpcoming = false;

  final List<String> _learningPaths = [
    'Mobile',
    'Backend',
    'DevOps',
  ];

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
        _availableLearningPaths = paths.isNotEmpty ? paths : _learningPaths;
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
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilters(),
              Expanded(
                child: _buildContent(),
              ),
            ],
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
            const SizedBox(width: 8),
            FilterChip(
              label: Text(_showUpcoming ? 'Próximos' : 'Activos'),
              selected: _showUpcoming,
              onSelected: (selected) {
                setState(() {
                  _showUpcoming = selected;
                });
                if (selected) {
                  context.read<AcademyBloc>().add(const LoadUpcomingCourses());
                } else {
                  context.read<AcademyBloc>().add(const LoadCourses());
                }
              },
              backgroundColor: BrandColors.cardBackground,
              selectedColor: BrandColors.primaryOrange.withOpacity(0.2),
              labelStyle: TextStyle(
                color: _showUpcoming ? BrandColors.primaryOrange : BrandColors.primaryWhite,
              ),
              side: BorderSide(
                color: _showUpcoming ? BrandColors.primaryOrange : BrandColors.grayMedium,
              ),
            ),
            if (_selectedLearningPath != null || _selectedDifficulty != null) ...[
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Limpiar'),
                onPressed: () {
                  setState(() {
                    _selectedLearningPath = null;
                    _selectedDifficulty = null;
                    _showUpcoming = false;
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

        if (state is AcademyError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: BrandColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar cursos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: BrandColors.primaryWhite,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BrandColors.grayMedium,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<AcademyBloc>().add(const RefreshCourses());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.primaryOrange,
                    foregroundColor: BrandColors.primaryWhite,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is AcademyLoaded) {
          final courses = _showUpcoming ? state.upcomingCourses : state.filteredCourses;

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showUpcoming ? Icons.schedule : Icons.school_outlined,
                    size: 64,
                    color: BrandColors.grayMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showUpcoming ? 'No hay cursos próximos' : 'No se encontraron cursos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: BrandColors.primaryWhite,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showUpcoming
                        ? 'Mantente al tanto de los próximos lanzamientos'
                        : 'Intenta con otros filtros o términos de búsqueda',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BrandColors.grayMedium,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
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
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _onCourseTap(Course course) {
    // Navigate to course detail screen
    // For now, we'll just show a placeholder
    // TODO: Create course detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Curso: ${course.title}'),
        backgroundColor: BrandColors.primaryOrange,
      ),
    );
  }
}
