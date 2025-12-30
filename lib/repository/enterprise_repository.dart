import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enterprise.dart';

abstract class EnterpriseRepository {
  Future<List<Service>> getServices();
  Future<List<PortfolioProject>> getPortfolioProjects();
  Future<PortfolioProject?> getPortfolioProjectById(String id);
  Future<void> submitContactForm(ContactSubmission submission);
}

class EnterpriseRepositoryImpl implements EnterpriseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _servicesCollection = 'services';
  static const String _portfolioCollection = 'portfolio';
  static const String _contactCollection = 'contact_submissions';

  @override
  Future<List<Service>> getServices() async {
    try {
      final snapshot = await _firestore
          .collection(_servicesCollection)
          .where('isPublished', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => Service.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener servicios: $e');
      rethrow;
    }
  }

  @override
  Future<List<PortfolioProject>> getPortfolioProjects() async {
    try {
      final snapshot = await _firestore
          .collection(_portfolioCollection)
          .where('isPublished', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => PortfolioProject.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error al obtener proyectos del portfolio: $e');
      rethrow;
    }
  }

  @override
  Future<PortfolioProject?> getPortfolioProjectById(String id) async {
    try {
      final doc = await _firestore.collection(_portfolioCollection).doc(id).get();
      if (doc.exists) {
        return PortfolioProject.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener proyecto por ID: $e');
      rethrow;
    }
  }

  @override
  Future<void> submitContactForm(ContactSubmission submission) async {
    try {
      await _firestore
          .collection(_contactCollection)
          .doc(submission.id)
          .set(submission.toFirestore());

      print('✅ Formulario de contacto enviado exitosamente');
    } catch (e) {
      print('❌ Error al enviar formulario de contacto: $e');
      rethrow;
    }
  }
}


