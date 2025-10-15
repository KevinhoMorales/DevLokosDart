import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/episode.dart';
import '../../repository/episode_repository.dart';
import 'episode_event.dart';
import 'episode_state.dart';

/// BLoC para manejar la lógica de negocio de episodios
/// Implementa el patrón MVVM separando la lógica de la UI
class EpisodeBloc extends Bloc<EpisodeEvent, EpisodeState> {
  final EpisodeRepository _repository;

  EpisodeBloc({
    required EpisodeRepository repository,
  }) : _repository = repository,
       super(const EpisodeInitial()) {
    
    // Registrar todos los manejadores de eventos
    on<LoadEpisodes>(_onLoadEpisodes);
    on<RefreshEpisodes>(_onRefreshEpisodes);
    on<SearchEpisodes>(_onSearchEpisodes);
    on<ClearSearch>(_onClearSearch);
    on<SelectEpisode>(_onSelectEpisode);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByTag>(_onFilterByTag);
    on<ClearFilters>(_onClearFilters);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadRelatedEpisodes>(_onLoadRelatedEpisodes);
  }

  /// Carga todos los episodios
  Future<void> _onLoadEpisodes(
    LoadEpisodes event,
    Emitter<EpisodeState> emit,
  ) async {
    try {
      print('🔄 BLoC: Iniciando carga de episodios...');
      emit(const EpisodeLoading());

      final episodes = await _repository.getAllEpisodes();
      final featuredEpisodes = episodes.where((episode) => episode.isFeatured).toList();

      print('✅ BLoC: ${episodes.length} episodios cargados');
      print('⭐ BLoC: ${featuredEpisodes.length} episodios destacados');

      emit(EpisodeLoaded(
        episodes: episodes,
        featuredEpisodes: featuredEpisodes,
        filteredEpisodes: episodes,
        searchQuery: '',
      ));
    } catch (e) {
      print('❌ BLoC: Error al cargar episodios - $e');
      emit(EpisodeError(
        message: 'Error al cargar episodios: $e',
      ));
    }
  }

  /// Refresca los episodios
  Future<void> _onRefreshEpisodes(
    RefreshEpisodes event,
    Emitter<EpisodeState> emit,
  ) async {
    // Mantener episodios en caché si hay error
    List<Episode> cachedEpisodes = [];
    if (state is EpisodeLoaded) {
      cachedEpisodes = (state as EpisodeLoaded).episodes;
    }

    try {
      emit(const EpisodeLoading());
      final episodes = await _repository.getAllEpisodes();
      final featuredEpisodes = episodes.where((episode) => episode.isFeatured).toList();

      emit(EpisodeLoaded(
        episodes: episodes,
        featuredEpisodes: featuredEpisodes,
        filteredEpisodes: episodes,
        searchQuery: '',
      ));
    } catch (e) {
      emit(EpisodeError(
        message: 'Error al refrescar episodios: $e',
        cachedEpisodes: cachedEpisodes.isNotEmpty ? cachedEpisodes : null,
      ));
    }
  }

  /// Busca episodios
  Future<void> _onSearchEpisodes(
    SearchEpisodes event,
    Emitter<EpisodeState> emit,
  ) async {
    if (state is! EpisodeLoaded) return;

    final currentState = state as EpisodeLoaded;
    
    if (event.query.isEmpty) {
      emit(currentState.copyWith(
        filteredEpisodes: currentState.episodes,
        searchQuery: '',
      ));
      return;
    }

    try {
      emit(EpisodeSearching(
        query: event.query,
        episodes: currentState.episodes,
      ));

      final searchResults = await _repository.searchEpisodes(event.query);

      emit(currentState.copyWith(
        filteredEpisodes: searchResults,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(EpisodeError(
        message: 'Error al buscar episodios: $e',
        cachedEpisodes: currentState.episodes,
      ));
    }
  }

  /// Limpia la búsqueda
  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<EpisodeState> emit,
  ) async {
    if (state is! EpisodeLoaded) return;

    final currentState = state as EpisodeLoaded;
    emit(currentState.copyWith(
      filteredEpisodes: currentState.episodes,
      searchQuery: '',
    ));
  }

  /// Selecciona un episodio específico
  Future<void> _onSelectEpisode(
    SelectEpisode event,
    Emitter<EpisodeState> emit,
  ) async {
    try {
      final episode = await _repository.getEpisodeById(event.episodeId);
      if (episode == null) {
        emit(EpisodeError(message: 'Episodio no encontrado'));
        return;
      }

      final relatedEpisodes = await _repository.getRelatedEpisodes(event.episodeId);

      emit(EpisodeSelected(
        episode: episode,
        relatedEpisodes: relatedEpisodes,
      ));
    } catch (e) {
      emit(EpisodeError(message: 'Error al seleccionar episodio: $e'));
    }
  }

  /// Filtra episodios por categoría
  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<EpisodeState> emit,
  ) async {
    if (state is! EpisodeLoaded) return;

    try {
      final filteredEpisodes = await _repository.getEpisodesByCategory(event.category);
      final currentState = state as EpisodeLoaded;

      emit(currentState.copyWith(
        filteredEpisodes: filteredEpisodes,
      ));
    } catch (e) {
      emit(EpisodeError(message: 'Error al filtrar por categoría: $e'));
    }
  }

  /// Filtra episodios por tag
  Future<void> _onFilterByTag(
    FilterByTag event,
    Emitter<EpisodeState> emit,
  ) async {
    if (state is! EpisodeLoaded) return;

    try {
      final filteredEpisodes = await _repository.getEpisodesByTag(event.tag);
      final currentState = state as EpisodeLoaded;

      emit(currentState.copyWith(
        filteredEpisodes: filteredEpisodes,
      ));
    } catch (e) {
      emit(EpisodeError(message: 'Error al filtrar por tag: $e'));
    }
  }

  /// Limpia todos los filtros
  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<EpisodeState> emit,
  ) async {
    if (state is! EpisodeLoaded) return;

    final currentState = state as EpisodeLoaded;
    emit(currentState.copyWith(
      filteredEpisodes: currentState.episodes,
    ));
  }

  /// Marca/desmarca episodio como favorito
  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<EpisodeState> emit,
  ) async {
    if (state is! EpisodeLoaded) return;

    // TODO: Implementar lógica de favoritos
    // Por ahora solo emitimos el estado actual
    print('⭐ BLoC: Toggle favorite para episodio ${event.episodeId}');
  }

  /// Carga episodios relacionados
  Future<void> _onLoadRelatedEpisodes(
    LoadRelatedEpisodes event,
    Emitter<EpisodeState> emit,
  ) async {
    try {
      final relatedEpisodes = await _repository.getRelatedEpisodes(event.episodeId);
      
      if (state is EpisodeSelected) {
        final currentState = state as EpisodeSelected;
        emit(currentState.copyWith(
          relatedEpisodes: relatedEpisodes,
        ));
      }
    } catch (e) {
      emit(EpisodeError(message: 'Error al cargar episodios relacionados: $e'));
    }
  }
}
