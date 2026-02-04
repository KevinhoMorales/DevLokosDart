import 'package:equatable/equatable.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventEvent {
  const LoadEvents();
}

class RefreshEvents extends EventEvent {
  const RefreshEvents();
}
