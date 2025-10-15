import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/episode.dart';
import '../utils/sample_data.dart';

class FirestoreSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Agrega episodios de ejemplo a Firestore
  static Future<void> seedEpisodes() async {
    try {
      final episodes = SampleData.getSampleEpisodes();
      
      // Agregar cada episodio a la colección 'episodes'
      for (final episode in episodes) {
        await _firestore
            .collection('episodes')
            .doc(episode.id)
            .set(episode.toMap());
      }
      
      print('✅ ${episodes.length} episodios agregados a Firestore');
    } catch (e) {
      print('❌ Error al agregar episodios: $e');
      rethrow;
    }
  }

  /// Limpia todos los episodios de Firestore
  static Future<void> clearEpisodes() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('episodes').get();
      
      // Eliminar cada documento
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ ${snapshot.docs.length} episodios eliminados de Firestore');
    } catch (e) {
      print('❌ Error al eliminar episodios: $e');
      rethrow;
    }
  }

  /// Obtiene el número de episodios en Firestore
  static Future<int> getEpisodeCount() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('episodes').get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error al contar episodios: $e');
      return 0;
    }
  }
}