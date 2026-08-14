import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/course.dart';
import '../../repository/academy_repository.dart';
import 'academy_event.dart';
import 'academy_state.dart';

class AcademyBloc extends Bloc<AcademyEvent, AcademyState> {
  final AcademyRepository _repository;

  AcademyBloc({
    required AcademyRepository repository,
  })  : _repository = repository,
        super(const AcademyInitial()) {
    on<LoadCourses>(_onLoadCourses);
    on<RefreshCourses>(_onRefreshCourses);
    on<LoadUpcomingCourses>(_onLoadUpcomingCourses);
    on<FilterCoursesByLearningPath>(_onFilterByLearningPath);
    on<FilterCoursesByDifficulty>(_onFilterByDifficulty);
    on<SearchCourses>(_onSearchCourses);
    on<SelectCourse>(_onSelectCourse);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadCourses(
    LoadCourses event,
    Emitter<AcademyState> emit,
  ) async {
    try {
      emit(const AcademyLoading());
      final courses = await _repository.getPublishedCourses();
      final upcomingCourses = await _repository.getUpcomingCourses();
      emit(AcademyLoaded(
        courses: courses,
        filteredCourses: courses,
        upcomingCourses: upcomingCourses,
      ));
    } catch (e) {
      emit(AcademyError(message: 'Error al cargar cursos: $e'));
    }
  }

  Future<void> _onRefreshCourses(
    RefreshCourses event,
    Emitter<AcademyState> emit,
  ) async {
    List<Course> cachedCourses = [];
    if (state is AcademyLoaded) {
      cachedCourses = (state as AcademyLoaded).courses;
    }

    try {
      emit(const AcademyLoading());
      final courses = await _repository.getPublishedCourses();
      final upcomingCourses = await _repository.getUpcomingCourses();
      emit(AcademyLoaded(
        courses: courses,
        filteredCourses: courses,
        upcomingCourses: upcomingCourses,
      ));
    } catch (e) {
      emit(AcademyError(
        message: 'Error al refrescar cursos: $e',
        cachedCourses: cachedCourses.isNotEmpty ? cachedCourses : null,
      ));
    }
  }

  Future<void> _onLoadUpcomingCourses(
    LoadUpcomingCourses event,
    Emitter<AcademyState> emit,
  ) async {
    if (state is! AcademyLoaded) return;

    final currentState = state as AcademyLoaded;
    emit(currentState.copyWith(showUpcoming: true));
  }

  Future<void> _onFilterByLearningPath(
    FilterCoursesByLearningPath event,
    Emitter<AcademyState> emit,
  ) async {
    if (state is! AcademyLoaded) return;

    final currentState = state as AcademyLoaded;
    final next = currentState.copyWith(
      selectedLearningPath: event.learningPath,
      clearLearningPath: event.learningPath.isEmpty,
    );
    emit(next.copyWith(filteredCourses: _applyFilters(next)));
  }

  Future<void> _onFilterByDifficulty(
    FilterCoursesByDifficulty event,
    Emitter<AcademyState> emit,
  ) async {
    if (state is! AcademyLoaded) return;

    final currentState = state as AcademyLoaded;
    final next = currentState.copyWith(
      selectedDifficulty: event.difficulty,
      clearDifficulty: event.difficulty.isEmpty,
    );
    emit(next.copyWith(filteredCourses: _applyFilters(next)));
  }

  Future<void> _onSearchCourses(
    SearchCourses event,
    Emitter<AcademyState> emit,
  ) async {
    if (state is! AcademyLoaded) return;

    final currentState = state as AcademyLoaded;
    final next = currentState.copyWith(searchQuery: event.query);
    emit(next.copyWith(filteredCourses: _applyFilters(next)));
  }

  /// Aplica path + dificultad + búsqueda como AND sobre el catálogo en memoria.
  List<Course> _applyFilters(AcademyLoaded state) {
    Iterable<Course> result = state.courses;

    final path = state.selectedLearningPath;
    if (path != null && path.isNotEmpty) {
      result = result.where((c) => c.learningPaths.contains(path));
    }

    final difficulty = state.selectedDifficulty;
    if (difficulty != null && difficulty.isNotEmpty) {
      result = result.where((c) => c.difficulty == difficulty);
    }

    final query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((c) {
        return c.title.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query) ||
            c.learningPaths.any((p) => p.toLowerCase().contains(query));
      });
    }

    return result.toList();
  }

  Future<void> _onSelectCourse(
    SelectCourse event,
    Emitter<AcademyState> emit,
  ) async {
    // Course selection logic can be handled here if needed
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<AcademyState> emit,
  ) async {
    if (state is! AcademyLoaded) return;

    final currentState = state as AcademyLoaded;
    emit(currentState.copyWith(
      filteredCourses: currentState.courses,
      clearLearningPath: true,
      clearDifficulty: true,
      searchQuery: '',
      showUpcoming: false,
    ));
  }
}
