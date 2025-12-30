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

    try {
      final filtered = await _repository.getCoursesByLearningPath(event.learningPath);
      emit(currentState.copyWith(
        filteredCourses: filtered,
        selectedLearningPath: event.learningPath,
      ));
    } catch (e) {
      emit(AcademyError(message: 'Error al filtrar por learning path: $e'));
    }
  }

  Future<void> _onFilterByDifficulty(
    FilterCoursesByDifficulty event,
    Emitter<AcademyState> emit,
  ) async {
    if (state is! AcademyLoaded) return;

    final currentState = state as AcademyLoaded;

    try {
      final filtered = await _repository.getCoursesByDifficulty(event.difficulty);
      emit(currentState.copyWith(
        filteredCourses: filtered,
        selectedDifficulty: event.difficulty,
      ));
    } catch (e) {
      emit(AcademyError(message: 'Error al filtrar por dificultad: $e'));
    }
  }

  Future<void> _onSearchCourses(
    SearchCourses event,
    Emitter<AcademyState> emit,
  ) async {
    if (state is! AcademyLoaded) return;

    final currentState = state as AcademyLoaded;

    if (event.query.isEmpty) {
      emit(currentState.copyWith(
        filteredCourses: currentState.courses,
        searchQuery: '',
      ));
      return;
    }

    try {
      final results = await _repository.searchCourses(event.query);
      emit(currentState.copyWith(
        filteredCourses: results,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(AcademyError(message: 'Error al buscar cursos: $e'));
    }
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
      selectedLearningPath: null,
      selectedDifficulty: null,
      searchQuery: '',
      showUpcoming: false,
    ));
  }
}


