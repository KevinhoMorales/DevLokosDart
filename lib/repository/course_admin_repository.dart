import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../config/environment_config.dart';

/// Repositorio para administrar cursos en Firestore
class CourseAdminRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene la referencia a la colección de cursos
  CollectionReference get _coursesCollection {
    return _firestore
        .collection(EnvironmentConfig.getUsersCollectionPath())
        .doc(EnvironmentConfig.getUsersCollectionPath())
        .collection('courses');
  }

  /// Crea un nuevo curso en Firestore
  Future<String> createCourse(Course course) async {
    try {
      final courseData = course.toFirestore();
      final docRef = await _coursesCollection.add(courseData);
      return docRef.id;
    } catch (e) {
      print('❌ Error al crear curso: $e');
      throw Exception('Error al crear curso: $e');
    }
  }

  /// Actualiza un curso existente
  Future<void> updateCourse(String courseId, Course course) async {
    try {
      final courseData = course.toFirestore();
      await _coursesCollection.doc(courseId).update(courseData);
    } catch (e) {
      print('❌ Error al actualizar curso: $e');
      throw Exception('Error al actualizar curso: $e');
    }
  }

  /// Elimina un curso
  Future<void> deleteCourse(String courseId) async {
    try {
      await _coursesCollection.doc(courseId).delete();
    } catch (e) {
      print('❌ Error al eliminar curso: $e');
      throw Exception('Error al eliminar curso: $e');
    }
  }

  /// Obtiene un curso por ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      final doc = await _coursesCollection.doc(courseId).get();
      if (doc.exists && doc.data() != null) {
        return Course.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener curso: $e');
      return null;
    }
  }

  /// Obtiene todos los cursos (para administración)
  Future<List<Course>> getAllCourses() async {
    try {
      final querySnapshot = await _coursesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Course.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('❌ Error al obtener cursos: $e');
      return [];
    }
  }
}
