class ProductStoreLink {
  final String label;
  final String url;

  const ProductStoreLink({
    required this.label,
    required this.url,
  });

  factory ProductStoreLink.fromMap(Map<String, dynamic> data) {
    return ProductStoreLink(
      label: data['label']?.toString() ?? '',
      url: data['url']?.toString() ?? '',
    );
  }
}

class Product {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String type;
  final List<ProductStoreLink> storeLinks;
  final bool isPublished;
  final int order;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.type,
    required this.storeLinks,
    this.isPublished = true,
    required this.order,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    final rawLinks = data['storeLinks'];
    final storeLinks = <ProductStoreLink>[];
    if (rawLinks is List) {
      for (final item in rawLinks) {
        if (item is Map) {
          final link = ProductStoreLink.fromMap(
            Map<String, dynamic>.from(item),
          );
          if (link.label.isNotEmpty && link.url.isNotEmpty) {
            storeLinks.add(link);
          }
        }
      }
    }

    return Product(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString(),
      type: data['type']?.toString() ?? 'other',
      storeLinks: storeLinks,
      isPublished: data['isPublished'] != false,
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'book':
        return 'Libro';
      case 'digital':
        return 'Digital';
      default:
        return 'Producto';
    }
  }
}
