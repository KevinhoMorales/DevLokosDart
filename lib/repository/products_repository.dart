import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

abstract class ProductsRepository {
  Future<List<Product>> getProducts();
}

class ProductsRepositoryImpl implements ProductsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _productsCollection = 'products';

  @override
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _firestore.collection(_productsCollection).get();
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .where((p) => p.isPublished)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return products;
    } catch (e) {
      print('❌ Error al obtener productos: $e');
      rethrow;
    }
  }
}
