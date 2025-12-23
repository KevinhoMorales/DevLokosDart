import 'package:cloud_firestore/cloud_firestore.dart';

class Tutorial {
  final String id;
  final String videoId; // YouTube video ID
  final String title;
  final String description;
  final String thumbnailUrl;
  final String category; // Backend, Frontend, Mobile, DevOps, AI, Databases
  final List<String> techStack; // SwiftUI, Firebase, Java, etc.
  final String level; // Beginner, Intermediate, Advanced
  final String? relatedCourseId; // Optional link to Academy course
  final int duration; // Duration in seconds
  final DateTime publishedAt;
  final DateTime createdAt;
  final bool isPublished;
  final int? viewCount;

  Tutorial({
    required this.id,
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.techStack,
    required this.level,
    this.relatedCourseId,
    required this.duration,
    required this.publishedAt,
    required this.createdAt,
    this.isPublished = true,
    this.viewCount,
  });

  factory Tutorial.fromFirestore(Map<String, dynamic> data, String id) {
    return Tutorial(
      id: id,
      videoId: data['videoId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      category: data['category'] ?? '',
      techStack: List<String>.from(data['techStack'] ?? []),
      level: data['level'] ?? 'Beginner',
      relatedCourseId: data['relatedCourseId'],
      duration: data['duration'] ?? 0,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['isPublished'] ?? true,
      viewCount: data['viewCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'techStack': techStack,
      'level': level,
      'relatedCourseId': relatedCourseId,
      'duration': duration,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
      'viewCount': viewCount,
    };
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Tutorial copyWith({
    String? id,
    String? videoId,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? category,
    List<String>? techStack,
    String? level,
    String? relatedCourseId,
    int? duration,
    DateTime? publishedAt,
    DateTime? createdAt,
    bool? isPublished,
    int? viewCount,
  }) {
    return Tutorial(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      techStack: techStack ?? this.techStack,
      level: level ?? this.level,
      relatedCourseId: relatedCourseId ?? this.relatedCourseId,
      duration: duration ?? this.duration,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      isPublished: isPublished ?? this.isPublished,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}

