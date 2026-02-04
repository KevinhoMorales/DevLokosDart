import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/event_repository.dart';
import '../../services/analytics_service.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  final EventRepository _repository;

  EventBloc({required EventRepository repository})
      : _repository = repository,
        super(const EventInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<RefreshEvents>(_onRefreshEvents);
  }

  Future<void> _onLoadEvents(LoadEvents event, Emitter<EventState> emit) async {
    await _fetchEvents(emit);
  }

  Future<void> _onRefreshEvents(RefreshEvents event, Emitter<EventState> emit) async {
    await _fetchEvents(emit);
  }

  Future<void> _fetchEvents(Emitter<EventState> emit) async {
    emit(const EventLoading());
    try {
      final events = await _repository.getActiveEventsForPublic();
      AnalyticsService.logEventsListViewed();
      emit(EventLoaded(events: events));
    } catch (e) {
      emit(EventError(message: 'Error al cargar eventos: $e'));
    }
  }
}
