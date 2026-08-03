import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enterprise.dart';
import '../services/web3forms_service.dart';
import '../services/remote_config_service.dart';

abstract class EnterpriseRepository {
  Future<List<Service>> getServices();
  Future<List<PortfolioProject>> getPortfolioProjects();
  Future<PortfolioProject?> getPortfolioProjectById(String id);
  Future<void> submitContactForm(ContactSubmission submission);
}

class EnterpriseRepositoryImpl implements EnterpriseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Web3FormsService _web3Forms = Web3FormsService();
  final RemoteConfigService _remoteConfig = RemoteConfigService();
  static const String _servicesCollection = 'services';
  static const String _portfolioCollection = 'portfolio';

  @override
  Future<List<Service>> getServices() async {
    try {
      // Filtrar/ordenar en memoria: evita índice compuesto isPublished + order.
      final snapshot = await _firestore.collection(_servicesCollection).get();

      final services = snapshot.docs
          .map((doc) => Service.fromFirestore(doc.data(), doc.id))
          .where((s) => s.isPublished)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      return services;
    } catch (e) {
      print('❌ Error al obtener servicios: $e');
      rethrow;
    }
  }

  @override
  Future<List<PortfolioProject>> getPortfolioProjects() async {
    try {
      final snapshot = await _firestore.collection(_portfolioCollection).get();

      final projects = snapshot.docs
          .map((doc) => PortfolioProject.fromFirestore(doc.data(), doc.id))
          .where((p) => p.isPublished)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      return projects;
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
    final accessKey = _remoteConfig.web3FormAccessKey;
    await _web3Forms.submitContactForm(
      accessKey: accessKey,
      submission: submission,
    );
  }
}
