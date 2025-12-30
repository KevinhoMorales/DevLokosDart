import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final List<String> learningObjectives;
  final String difficulty; // Beginner, Intermediate, Advanced
  final int duration; // Total duration in minutes
  final String? thumbnailUrl;
  final List<String> learningPaths; // Mobile, Backend, DevOps
  final List<Module> modules;
  final String? finalProjectId;
  final bool isPublished;
  final bool isPaid; // Future monetization
  final double? price; // Future monetization
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final int? enrollmentCount;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.learningObjectives,
    required this.difficulty,
    required this.duration,
    this.thumbnailUrl,
    required this.learningPaths,
    required this.modules,
    this.finalProjectId,
    this.isPublished = false,
    this.isPaid = false,
    this.price,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.enrollmentCount,
  });

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    final modulesData = data['modules'] as List<dynamic>? ?? [];
    final modules = modulesData.map((m) => Module.fromFirestore(m as Map<String, dynamic>, m['id'] ?? '')).toList();

    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      learningObjectives: List<String>.from(data['learningObjectives'] ?? []),
      difficulty: data['difficulty'] ?? 'Beginner',
      duration: data['duration'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'],
      learningPaths: List<String>.from(data['learningPaths'] ?? []),
      modules: modules,
      finalProjectId: data['finalProjectId'],
      isPublished: data['isPublished'] ?? false,
      isPaid: data['isPaid'] ?? false,
      price: (data['price'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      enrollmentCount: data['enrollmentCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'learningObjectives': learningObjectives,
      'difficulty': difficulty,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
      'learningPaths': learningPaths,
      'modules': modules.map((m) => m.toFirestore()).toList(),
      'finalProjectId': finalProjectId,
      'isPublished': isPublished,
      'isPaid': isPaid,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'enrollmentCount': enrollmentCount,
    };
  }

  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? learningObjectives,
    String? difficulty,
    int? duration,
    String? thumbnailUrl,
    List<String>? learningPaths,
    List<Module>? modules,
    String? finalProjectId,
    bool? isPublished,
    bool? isPaid,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    int? enrollmentCount,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      learningPaths: learningPaths ?? this.learningPaths,
      modules: modules ?? this.modules,
      finalProjectId: finalProjectId ?? this.finalProjectId,
      isPublished: isPublished ?? this.isPublished,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
    );
  }
}

class Module {
  final String id;
  final String title;
  final String description;
  final int order;
  final List<Lesson> lessons;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.lessons,
  });

  factory Module.fromFirestore(Map<String, dynamic> data, String id) {
    final lessonsData = data['lessons'] as List<dynamic>? ?? [];
    final lessons = lessonsData.map((l) => Lesson.fromFirestore(l as Map<String, dynamic>, l['id'] ?? '')).toList();

    return Module(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      order: data['order'] ?? 0,
      lessons: lessons,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'lessons': lessons.map((l) => l.toFirestore()).toList(),
    };
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final LessonType type; // video, text, external
  final String? videoId; // YouTube video ID (if type is video)
  final String? content; // Text content (if type is text)
  final String? externalUrl; // External resource URL (if type is external)
  final int order;
  final int? duration; // Duration in minutes (for video lessons)
  final bool isPublished;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.videoId,
    this.content,
    this.externalUrl,
    required this.order,
    this.duration,
    this.isPublished = true,
  });

  factory Lesson.fromFirestore(Map<String, dynamic> data, String id) {
    return Lesson(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: LessonType.fromString(data['type'] ?? 'video'),
      videoId: data['videoId'],
      content: data['content'],
      externalUrl: data['externalUrl'],
      order: data['order'] ?? 0,
      duration: data['duration'],
      isPublished: data['isPublished'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'videoId': videoId,
      'content': content,
      'externalUrl': externalUrl,
      'order': order,
      'duration': duration,
      'isPublished': isPublished,
    };
  }
}

enum LessonType {
  video,
  text,
  external;

  static LessonType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'video':
        return LessonType.video;
      case 'text':
        return LessonType.text;
      case 'external':
        return LessonType.external;
      default:
        return LessonType.video;
    }
  }

  @override
  String toString() {
    switch (this) {
      case LessonType.video:
        return 'video';
      case LessonType.text:
        return 'text';
      case LessonType.external:
        return 'external';
    }
  }
}


