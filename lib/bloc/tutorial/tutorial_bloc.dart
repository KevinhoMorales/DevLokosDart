import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/tutorial.dart';
import '../../repository/tutorial_repository.dart';
import 'tutorial_event.dart';
import 'tutorial_state.dart';

class TutorialBloc extends Bloc<TutorialEvent, TutorialState> {
  final TutorialRepository _repository;

  TutorialBloc({
    required TutorialRepository repository,
  })  : _repository = repository,
        super(const TutorialInitial()) {
    on<LoadTutorials>(_onLoadTutorials);
    on<RefreshTutorials>(_onRefreshTutorials);
    on<SearchTutorials>(_onSearchTutorials);
    on<FilterTutorialsByCategory>(_onFilterByCategory);
    on<FilterTutorialsByTechStack>(_onFilterByTechStack);
    on<FilterTutorialsByLevel>(_onFilterByLevel);
    on<ClearTutorialFilters>(_onClearFilters);
    on<SelectTutorial>(_onSelectTutorial);
  }

  Future<void> _onLoadTutorials(
    LoadTutorials event,
    Emitter<TutorialState> emit,
  ) async {
    try {
      emit(const TutorialLoading());
      final tutorials = await _repository.getAllTutorials();
      emit(TutorialLoaded(
        tutorials: tutorials,
        filteredTutorials: tutorials,
      ));
    } catch (e) {
      emit(TutorialError(message: 'Error al cargar tutoriales: $e'));
    }
  }

  Future<void> _onRefreshTutorials(
    RefreshTutorials event,
    Emitter<TutorialState> emit,
  ) async {
    List<Tutorial> cachedTutorials = [];
    if (state is TutorialLoaded) {
      cachedTutorials = (state as TutorialLoaded).tutorials;
    }

    try {
      emit(const TutorialLoading());
      final tutorials = await _repository.getAllTutorials();
      emit(TutorialLoaded(
        tutorials: tutorials,
        filteredTutorials: tutorials,
      ));
    } catch (e) {
      emit(TutorialError(
        message: 'Error al refrescar tutoriales: $e',
        cachedTutorials: cachedTutorials.isNotEmpty ? cachedTutorials : null,
      ));
    }
  }

  Future<void> _onSearchTutorials(
    SearchTutorials event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final currentState = state as TutorialLoaded;

    if (event.query.isEmpty) {
      emit(currentState.copyWith(
        filteredTutorials: currentState.tutorials,
        searchQuery: '',
      ));
      return;
    }

    try {
      final results = await _repository.searchTutorials(event.query);
      emit(currentState.copyWith(
        filteredTutorials: results,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(TutorialError(message: 'Error al buscar tutoriales: $e'));
    }
  }

  Future<void> _onFilterByCategory(
    FilterTutorialsByCategory event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final currentState = state as TutorialLoaded;

    try {
      final filtered = await _repository.getTutorialsByCategory(event.category);
      emit(currentState.copyWith(
        filteredTutorials: filtered,
        selectedCategory: event.category,
      ));
    } catch (e) {
      emit(TutorialError(message: 'Error al filtrar por categoría: $e'));
    }
  }

  Future<void> _onFilterByTechStack(
    FilterTutorialsByTechStack event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final currentState = state as TutorialLoaded;

    try {
      final filtered = await _repository.getTutorialsByTechStack(event.techStack);
      emit(currentState.copyWith(
        filteredTutorials: filtered,
        selectedTechStack: event.techStack,
      ));
    } catch (e) {
      emit(TutorialError(message: 'Error al filtrar por tech stack: $e'));
    }
  }

  Future<void> _onFilterByLevel(
    FilterTutorialsByLevel event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final currentState = state as TutorialLoaded;

    try {
      final filtered = await _repository.getTutorialsByLevel(event.level);
      emit(currentState.copyWith(
        filteredTutorials: filtered,
        selectedLevel: event.level,
      ));
    } catch (e) {
      emit(TutorialError(message: 'Error al filtrar por nivel: $e'));
    }
  }

  Future<void> _onClearFilters(
    ClearTutorialFilters event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final currentState = state as TutorialLoaded;
    emit(currentState.copyWith(
      filteredTutorials: currentState.tutorials,
      selectedCategory: null,
      selectedTechStack: null,
      selectedLevel: null,
      searchQuery: '',
    ));
  }

  Future<void> _onSelectTutorial(
    SelectTutorial event,
    Emitter<TutorialState> emit,
  ) async {
    // Tutorial selection logic can be handled here if needed
    // For now, we'll just keep the current state
  }
}


