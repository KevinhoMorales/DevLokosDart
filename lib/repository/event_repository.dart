import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../config/environment_config.dart';

/// Repositorio para eventos en Firestore
/// Colección: {env}/{env}/events (ej: prod/prod/events)
class EventRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection {
    return _firestore
        .collection(EnvironmentConfig.getUsersCollectionPath())
        .doc(EnvironmentConfig.getUsersCollectionPath())
        .collection('events');
  }

  /// Obtiene eventos activos (solo próximos: hoy y futuros)
  Future<List<Event>> getActiveEvents() async {
    try {
      final all = await getActiveEventsForPublic();
      return all.where((e) => !e.isPast).toList();
    } catch (e) {
      print('❌ Error al obtener eventos: $e');
      return [];
    }
  }

  /// Obtiene todos los eventos activos (próximos + pasados) para la vista pública.
  /// Próximos ordenados por fecha asc, pasados por fecha desc.
  Future<List<Event>> getActiveEventsForPublic() async {
    try {
      final querySnapshot = await _eventsCollection.get();

      final events = querySnapshot.docs
          .map((doc) => Event.fromFirestore(doc.data(), doc.id))
          .where((e) => e.isActive)
          .toList();

      final upcoming = events.where((e) => !e.isPast).toList()
        ..sort((a, b) {
          if (a.eventDate == null && b.eventDate == null) return 0;
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return a.eventDate!.compareTo(b.eventDate!);
        });
      final past = events.where((e) => e.isPast).toList()
        ..sort((a, b) {
          if (a.eventDate == null && b.eventDate == null) return 0;
          if (a.eventDate == null) return 1;
          if (b.eventDate == null) return -1;
          return b.eventDate!.compareTo(a.eventDate!);
        });

      return [...upcoming, ...past];
    } catch (e) {
      print('❌ Error al obtener eventos: $e');
      return [];
    }
  }

  /// Obtiene un evento por ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (doc.exists && doc.data() != null) {
        return Event.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener evento: $e');
      return null;
    }
  }

  /// Crea un nuevo evento (admin)
  Future<String> createEvent(Event event) async {
    try {
      final data = event.toFirestore();
      final docRef = await _eventsCollection.add(data);
      return docRef.id;
    } catch (e) {
      print('❌ Error al crear evento: $e');
      throw Exception('Error al crear evento: $e');
    }
  }

  /// Actualiza un evento (admin)
  Future<void> updateEvent(String eventId, Event event) async {
    try {
      final data = event.toFirestore();
      await _eventsCollection.doc(eventId).update(data);
    } catch (e) {
      print('❌ Error al actualizar evento: $e');
      throw Exception('Error al actualizar evento: $e');
    }
  }

  /// Elimina un evento (soft delete: isActive = false)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).update({'isActive': false});
    } catch (e) {
      print('❌ Error al eliminar evento: $e');
      throw Exception('Error al eliminar evento: $e');
    }
  }

  /// Elimina un evento permanentemente (admin)
  Future<void> deleteEventPermanently(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      print('❌ Error al eliminar evento: $e');
      throw Exception('Error al eliminar evento: $e');
    }
  }

  /// Obtiene todos los eventos (admin - incluye inactivos)
  Future<List<Event>> getAllEvents() async {
    try {
      final querySnapshot = await _eventsCollection.get();

      final events = querySnapshot.docs
          .map((doc) => Event.fromFirestore(doc.data(), doc.id))
          .toList();

      events.sort((a, b) {
        if (a.eventDate == null && b.eventDate == null) return 0;
        if (a.eventDate == null) return 1;
        if (b.eventDate == null) return -1;
        return a.eventDate!.compareTo(b.eventDate!);
      });

      return events;
    } catch (e) {
      print('❌ Error al obtener eventos: $e');
      return [];
    }
  }
}
