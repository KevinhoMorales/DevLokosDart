import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de evento para DevLokos (Café Cursor, Meetups, Workshops, etc.)
class Event {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final DateTime? eventDate;
  final String location;
  final String city;
  final String? registrationUrl;
  final DateTime createdAt;
  final bool isActive;

  const Event({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    this.eventDate,
    required this.location,
    required this.city,
    this.registrationUrl,
    required this.createdAt,
    this.isActive = true,
  });

  factory Event.fromFirestore(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      imageUrl: data['imageUrl'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate(),
      location: data['location'] as String? ?? '',
      city: data['city'] as String? ?? '',
      registrationUrl: data['registrationUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'location': location,
      'city': city,
      'registrationUrl': registrationUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  Event copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
    String? city,
    String? registrationUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      city: city ?? this.city,
      registrationUrl: registrationUrl ?? this.registrationUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  static const List<String> _monthsShort = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String get formattedDate {
    if (eventDate == null) return '';
    final d = eventDate!;
    return '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';
  }

  /// Día numérico para badge visual (ej. "28").
  String get dayLabel {
    if (eventDate == null) return '';
    return eventDate!.day.toString().padLeft(2, '0');
  }

  /// Mes corto en español para badge (ej. "Feb").
  String get monthLabel {
    if (eventDate == null) return '';
    return _monthsShort[eventDate!.month - 1];
  }

  /// Etiqueta de estado para UI.
  String get statusLabel {
    if (isToday) return 'Hoy';
    if (isPast) return 'Pasado';
    return 'Próximo';
  }

  String get formattedDateTime {
    if (eventDate == null) return '';
    final d = eventDate!;
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$formattedDate${time != '00:00' ? ' · $time' : ''}';
  }

  String get locationDisplay {
    if (location.isEmpty && city.isEmpty) return '';
    if (location.isNotEmpty && city.isNotEmpty) return '$location, $city';
    return location.isNotEmpty ? location : city;
  }

  /// Verdadero si la fecha del evento ya pasó (después de medianoche de ese día)
  bool get isPast {
    if (eventDate == null) return false;
    final endOfDay = DateTime(eventDate!.year, eventDate!.month, eventDate!.day, 23, 59, 59);
    return DateTime.now().isAfter(endOfDay);
  }

  /// Verdadero si el evento es hoy
  bool get isToday {
    if (eventDate == null) return false;
    final now = DateTime.now();
    return eventDate!.year == now.year &&
        eventDate!.month == now.month &&
        eventDate!.day == now.day;
  }
}
