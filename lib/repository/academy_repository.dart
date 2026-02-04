import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../config/environment_config.dart';

abstract class AcademyRepository {
  Future<List<Course>> getAllCourses();
  Future<List<Course>> getPublishedCourses();
  Future<List<Course>> getUpcomingCourses();
  Future<List<Course>> getCoursesByLearningPath(String path);
  Future<List<Course>> getCoursesByDifficulty(String difficulty);
  Future<Course?> getCourseById(String id);
  Future<List<String>> getAllLearningPaths();
  Future<List<Course>> searchCourses(String query);
}

class AcademyRepositoryImpl implements AcademyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Obtiene la referencia a la colección de cursos según el ambiente
  CollectionReference get _coursesCollection {
    return _firestore
        .collection(EnvironmentConfig.getUsersCollectionPath())
        .doc(EnvironmentConfig.getUsersCollectionPath())
        .collection('courses');
  }

  @override
  Future<List<Course>> getAllCourses() async {
    try {
      final snapshot = await _coursesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener cursos: $e');
      rethrow;
    }
  }

  @override
  Future<List<Course>> getPublishedCourses() async {
    try {
      // Obtener todos y filtrar/ordenar en memoria para evitar depender del
      // índice compuesto (isPublished + publishedAt) que puede no existir
      final snapshot = await _coursesCollection.get();

      final courses = snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((c) => c.isPublished)
          .toList();

      courses.sort((a, b) {
        final aAt = a.publishedAt ?? a.createdAt;
        final bAt = b.publishedAt ?? b.createdAt;
        return bAt.compareTo(aAt); // Más recientes primero
      });

      return courses;
    } catch (e) {
      print('❌ Error al obtener cursos publicados: $e');
      rethrow;
    }
  }

  @override
  Future<List<Course>> getUpcomingCourses() async {
    try {
      final snapshot = await _coursesCollection.get();

      final courses = snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((c) => !c.isPublished)
          .toList();

      courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return courses;
    } catch (e) {
      print('❌ Error al obtener cursos próximos: $e');
      rethrow;
    }
  }

  @override
  Future<List<Course>> getCoursesByLearningPath(String path) async {
    try {
      final published = await getPublishedCourses();
      final filtered = published
          .where((c) => c.learningPaths.contains(path))
          .toList();
      return filtered;
    } catch (e) {
      print('❌ Error al obtener cursos por learning path: $e');
      rethrow;
    }
  }

  @override
  Future<List<Course>> getCoursesByDifficulty(String difficulty) async {
    try {
      final published = await getPublishedCourses();
      final filtered = published
          .where((c) => c.difficulty == difficulty)
          .toList();
      return filtered;
    } catch (e) {
      print('❌ Error al obtener cursos por dificultad: $e');
      rethrow;
    }
  }

  @override
  Future<Course?> getCourseById(String id) async {
    try {
      final doc = await _coursesCollection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Course.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener curso por ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getAllLearningPaths() async {
    try {
      final courses = await getPublishedCourses();
      final allPaths = <String>{};
      for (final course in courses) {
        allPaths.addAll(course.learningPaths);
      }
      return allPaths.toList()..sort();
    } catch (e) {
      print('❌ Error al obtener learning paths: $e');
      return [];
    }
  }

  @override
  Future<List<Course>> searchCourses(String query) async {
    try {
      if (query.isEmpty) return await getPublishedCourses();

      final allCourses = await getPublishedCourses();
      final lowercaseQuery = query.toLowerCase().trim();

      return allCourses.where((course) {
        final titleMatch = course.title.toLowerCase().contains(lowercaseQuery);
        final descriptionMatch = course.description.toLowerCase().contains(lowercaseQuery);
        final objectivesMatch = course.learningObjectives.any(
          (obj) => obj.toLowerCase().contains(lowercaseQuery),
        );
        final pathMatch = course.learningPaths.any(
          (path) => path.toLowerCase().contains(lowercaseQuery),
        );

        return titleMatch || descriptionMatch || objectivesMatch || pathMatch;
      }).toList();
    } catch (e) {
      print('❌ Error al buscar cursos: $e');
      rethrow;
    }
  }
}


