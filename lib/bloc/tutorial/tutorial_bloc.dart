import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/tutorial_repository.dart';
import 'tutorial_event.dart';
import 'tutorial_state.dart';

class TutorialBloc extends Bloc<TutorialEvent, TutorialState> {
  final TutorialRepository _repository;

  TutorialBloc({
    required TutorialRepository repository,
  })  : _repository = repository,
        super(const TutorialInitial()) {
    on<LoadPlaylists>(_onLoadPlaylists);
    on<SelectPlaylist>(_onSelectPlaylist);
    on<RefreshTutorials>(_onRefreshTutorials);
    on<SearchTutorials>(_onSearchTutorials);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onLoadPlaylists(
    LoadPlaylists event,
    Emitter<TutorialState> emit,
  ) async {
    try {
      // Cache-first: evita Loading si hay datos cacheados (perceived performance)
      final playlists = await _repository.getPlaylists(refresh: false);
      if (playlists.isEmpty) {
        emit(const TutorialLoading());
        final freshPlaylists = await _repository.getPlaylists(refresh: true);
        if (freshPlaylists.isEmpty) {
          emit(const TutorialError(message: 'No hay playlists disponibles.'));
          return;
        }
        final first = freshPlaylists.first;
        final tutorials = await _repository.getTutorialsByPlaylist(
          first.id,
          refresh: true,
        );
        emit(TutorialLoaded(
          playlists: freshPlaylists,
          selectedPlaylistId: first.id,
          selectedPlaylistTitle: first.title,
          tutorials: tutorials,
          filteredTutorials: tutorials,
        ));
        return;
      }

      final first = playlists.first;
      final tutorials = await _repository.getTutorialsByPlaylist(
        first.id,
        refresh: false,
      );

      emit(TutorialLoaded(
        playlists: playlists,
        selectedPlaylistId: first.id,
        selectedPlaylistTitle: first.title,
        tutorials: tutorials,
        filteredTutorials: tutorials,
      ));

      // Stale-while-revalidate: refrescar en background sin bloquear
      _refreshInBackground(first.id, first.title, null, emit);
    } catch (e) {
      emit(TutorialError(message: _toUserFriendlyMessage(e)));
    }
  }

  void _refreshInBackground(
    String playlistId,
    String playlistTitle,
    String? searchQuery,
    Emitter<TutorialState> emit,
  ) {
    Future.microtask(() async {
      try {
        final freshPlaylists = await _repository.getPlaylists(refresh: true);
        if (freshPlaylists.isEmpty) return;
        final freshTutorials = await _repository.getTutorialsByPlaylist(
          playlistId,
          refresh: true,
        );
        final filtered = searchQuery != null && searchQuery.isNotEmpty
            ? await _repository.searchByTitle(searchQuery, freshTutorials)
            : freshTutorials;
        emit(TutorialLoaded(
          playlists: freshPlaylists,
          selectedPlaylistId: playlistId,
          selectedPlaylistTitle: playlistTitle,
          tutorials: freshTutorials,
          filteredTutorials: filtered,
          searchQuery: searchQuery ?? '',
        ));
      } catch (_) {
        // Silently fail; cached data already shown
      }
    });
  }

  Future<void> _onSelectPlaylist(
    SelectPlaylist event,
    Emitter<TutorialState> emit,
  ) async {
    final prevState = state;
    if (prevState is TutorialLoaded &&
        prevState.selectedPlaylistId == event.playlistId) {
      return;
    }

    final playlists = prevState is TutorialLoaded
        ? prevState.playlists
        : await _repository.getPlaylists(refresh: false);

    if (playlists.isEmpty) {
      emit(const TutorialError(message: 'No hay playlists disponibles.'));
      return;
    }

    try {
      var stillWaiting = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (stillWaiting) {
          emit(const TutorialLoading());
        }
      });
      final tutorials = await _repository.getTutorialsByPlaylist(
        event.playlistId,
        refresh: false,
      );
      stillWaiting = false;

      emit(TutorialLoaded(
        playlists: playlists,
        selectedPlaylistId: event.playlistId,
        selectedPlaylistTitle: event.playlistTitle,
        tutorials: tutorials,
        filteredTutorials: tutorials,
        searchQuery: '',
      ));
    } catch (e) {
      emit(TutorialError(message: _toUserFriendlyMessage(e)));
    }
  }

  Future<void> _onRefreshTutorials(
    RefreshTutorials event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final current = state as TutorialLoaded;
    final playlistId = current.selectedPlaylistId;
    if (playlistId == null) return;

    try {
      emit(current.copyWith(
        tutorials: [],
        filteredTutorials: [],
      ));
      emit(const TutorialLoading());

      final tutorials = await _repository.getTutorialsByPlaylist(
        playlistId,
        refresh: true,
      );

      emit(TutorialLoaded(
        playlists: current.playlists,
        selectedPlaylistId: playlistId,
        selectedPlaylistTitle: current.selectedPlaylistTitle,
        tutorials: tutorials,
        filteredTutorials: current.searchQuery.isEmpty
            ? tutorials
            : tutorials
                .where((t) => t.title
                    .toLowerCase()
                    .contains(current.searchQuery.toLowerCase()))
                .toList(),
        searchQuery: current.searchQuery,
      ));
    } catch (e) {
      emit(TutorialError(
        message: _toUserFriendlyMessage(e),
        cachedTutorials: current.tutorials,
      ));
    }
  }

  Future<void> _onSearchTutorials(
    SearchTutorials event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final current = state as TutorialLoaded;

    if (event.query.isEmpty) {
      emit(current.copyWith(
        filteredTutorials: current.tutorials,
        searchQuery: '',
      ));
      return;
    }

    final filtered = await _repository.searchByTitle(
      event.query,
      current.tutorials,
    );

    emit(current.copyWith(
      filteredTutorials: filtered,
      searchQuery: event.query,
    ));
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<TutorialState> emit,
  ) async {
    if (state is! TutorialLoaded) return;

    final current = state as TutorialLoaded;
    emit(current.copyWith(
      filteredTutorials: current.tutorials,
      searchQuery: '',
    ));
  }

  static String _toUserFriendlyMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('socket')) {
      return 'Revisa tu conexión a internet e intenta de nuevo.';
    }
    if (msg.contains('firestore') ||
        msg.contains('index') ||
        msg.contains('failed-precondition')) {
      return 'Los tutoriales no están disponibles en este momento. Intenta más tarde.';
    }
    if (msg.contains('permission') || msg.contains('unavailable')) {
      return 'No se pudo acceder a los tutoriales. Intenta de nuevo.';
    }
    return 'No pudimos cargar los tutoriales. Intenta de nuevo en unos momentos.';
  }
}
