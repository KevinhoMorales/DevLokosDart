class Episode {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String youtubeVideoId;
  final String duration;
  final DateTime publishedDate;
  final String category;
  final List<String> tags;
  final bool isFeatured;

  Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.youtubeVideoId,
    required this.duration,
    required this.publishedDate,
    required this.category,
    required this.tags,
    this.isFeatured = false,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      youtubeVideoId: json['youtubeVideoId'] ?? '',
      duration: json['duration'] ?? '0:00',
      publishedDate: DateTime.parse(json['publishedDate'] ?? DateTime.now().toIso8601String()),
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'youtubeVideoId': youtubeVideoId,
      'duration': duration,
      'publishedDate': publishedDate.toIso8601String(),
      'category': category,
      'tags': tags,
      'isFeatured': isFeatured,
    };
  }

  Episode copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? youtubeVideoId,
    String? duration,
    DateTime? publishedDate,
    String? category,
    List<String>? tags,
    bool? isFeatured,
  }) {
    return Episode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      duration: duration ?? this.duration,
      publishedDate: publishedDate ?? this.publishedDate,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  String toString() {
    return 'Episode(id: $id, title: $title, youtubeVideoId: $youtubeVideoId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Episode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}