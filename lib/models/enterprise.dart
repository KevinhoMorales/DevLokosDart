import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String title;
  final String description;
  final String icon; // Icon name or emoji
  final List<String> features;
  final int order;
  final bool isPublished;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.features,
    required this.order,
    this.isPublished = true,
  });

  factory Service.fromFirestore(Map<String, dynamic> data, String id) {
    return Service(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '💼',
      features: List<String>.from(data['features'] ?? []),
      order: data['order'] ?? 0,
      isPublished: data['isPublished'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'features': features,
      'order': order,
      'isPublished': isPublished,
    };
  }
}

class PortfolioProject {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final List<String> technologies;
  final String category; // Web, Mobile, Backend, etc.
  final String? projectUrl;
  final String? caseStudyUrl;
  final DateTime createdAt;
  final bool isPublished;
  final int order;

  PortfolioProject({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.technologies,
    required this.category,
    this.projectUrl,
    this.caseStudyUrl,
    required this.createdAt,
    this.isPublished = true,
    required this.order,
  });

  factory PortfolioProject.fromFirestore(Map<String, dynamic> data, String id) {
    return PortfolioProject(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      technologies: List<String>.from(data['technologies'] ?? []),
      category: data['category'] ?? '',
      projectUrl: data['projectUrl'],
      caseStudyUrl: data['caseStudyUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['isPublished'] ?? true,
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'technologies': technologies,
      'category': category,
      'projectUrl': projectUrl,
      'caseStudyUrl': caseStudyUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
      'order': order,
    };
  }
}

class ContactSubmission {
  final String id;
  final String name;
  final String email;
  final String? company;
  final String message;
  final String? projectType; // Custom Software, Consulting, etc.
  final DateTime submittedAt;
  final bool isProcessed;
  final String? notes; // Admin notes

  ContactSubmission({
    required this.id,
    required this.name,
    required this.email,
    this.company,
    required this.message,
    this.projectType,
    required this.submittedAt,
    this.isProcessed = false,
    this.notes,
  });

  factory ContactSubmission.fromFirestore(Map<String, dynamic> data, String id) {
    return ContactSubmission(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      company: data['company'],
      message: data['message'] ?? '',
      projectType: data['projectType'],
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isProcessed: data['isProcessed'] ?? false,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'company': company,
      'message': message,
      'projectType': projectType,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'isProcessed': isProcessed,
      'notes': notes,
    };
  }
}


