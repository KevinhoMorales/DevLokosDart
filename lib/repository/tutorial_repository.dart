import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tutorial.dart';

abstract class TutorialRepository {
  Future<List<Tutorial>> getAllTutorials();
  Future<List<Tutorial>> getTutorialsByCategory(String category);
  Future<List<Tutorial>> getTutorialsByTechStack(String tech);
  Future<List<Tutorial>> getTutorialsByLevel(String level);
  Future<List<Tutorial>> searchTutorials(String query);
  Future<Tutorial?> getTutorialById(String id);
  Future<List<String>> getAllCategories();
  Future<List<String>> getAllTechStacks();
}

class TutorialRepositoryImpl implements TutorialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'tutorials';

  @override
  Future<List<Tutorial>> getAllTutorials() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Tutorial.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener tutoriales: $e');
      rethrow;
    }
  }

  @override
  Future<List<Tutorial>> getTutorialsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .where('category', isEqualTo: category)
          .orderBy('publishedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Tutorial.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener tutoriales por categoría: $e');
      rethrow;
    }
  }

  @override
  Future<List<Tutorial>> getTutorialsByTechStack(String tech) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .where('techStack', arrayContains: tech)
          .orderBy('publishedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Tutorial.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener tutoriales por tech stack: $e');
      rethrow;
    }
  }

  @override
  Future<List<Tutorial>> getTutorialsByLevel(String level) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .where('level', isEqualTo: level)
          .orderBy('publishedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Tutorial.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener tutoriales por nivel: $e');
      rethrow;
    }
  }

  @override
  Future<List<Tutorial>> searchTutorials(String query) async {
    try {
      if (query.isEmpty) return await getAllTutorials();

      final allTutorials = await getAllTutorials();
      final lowercaseQuery = query.toLowerCase().trim();

      return allTutorials.where((tutorial) {
        final titleMatch = tutorial.title.toLowerCase().contains(lowercaseQuery);
        final descriptionMatch = tutorial.description.toLowerCase().contains(lowercaseQuery);
        final categoryMatch = tutorial.category.toLowerCase().contains(lowercaseQuery);
        final techMatch = tutorial.techStack.any(
          (tech) => tech.toLowerCase().contains(lowercaseQuery),
        );

        return titleMatch || descriptionMatch || categoryMatch || techMatch;
      }).toList();
    } catch (e) {
      print('❌ Error al buscar tutoriales: $e');
      rethrow;
    }
  }

  @override
  Future<Tutorial?> getTutorialById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Tutorial.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener tutorial por ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    try {
      final tutorials = await getAllTutorials();
      return tutorials.map((t) => t.category).toSet().toList()..sort();
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getAllTechStacks() async {
    try {
      final tutorials = await getAllTutorials();
      final allTechStacks = <String>{};
      for (final tutorial in tutorials) {
        allTechStacks.addAll(tutorial.techStack);
      }
      return allTechStacks.toList()..sort();
    } catch (e) {
      print('❌ Error al obtener tech stacks: $e');
      return [];
    }
  }
}

