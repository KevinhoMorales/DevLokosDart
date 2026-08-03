import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import '../../repository/products_repository.dart';
import '../../services/analytics_service.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Product? product;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product == null) {
      _load();
    } else {
      _isLoading = false;
      _logViewed(_product!);
    }
  }

  void _logViewed(Product product) {
    AnalyticsService.logProductViewed(
      productId: product.id,
      productTitle: product.title,
      productType: product.type,
    );
  }

  Future<void> _load() async {
    final product =
        await ProductsRepositoryImpl().getProductById(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = product;
      _isLoading = false;
      _error = product == null ? 'Producto no encontrado' : null;
    });
    if (product != null) _logViewed(product);
  }

  Future<void> _openStore(Product product, ProductStoreLink link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.cardBackground,
        title: Text(
          'Abrir ${link.label}',
          style: const TextStyle(color: BrandColors.primaryWhite),
        ),
        content: Text(
          '¿Quieres abrir ${link.label} para comprar este producto?',
          style: const TextStyle(color: BrandColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Abrir',
              style: TextStyle(
                color: BrandColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await AnalyticsService.logProductStoreClicked(
      productId: product.id,
      storeLabel: link.label,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(title: 'Producto', showBackButton: true),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
          ),
        ),
      );
    }

    if (_product == null || _error != null) {
      return Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(title: 'Producto', showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _error ?? 'Producto no encontrado',
              style: const TextStyle(color: BrandColors.grayMedium),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final product = _product!;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(title: product.typeLabel, showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCover(product: product),
                  const SizedBox(height: 20),
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: BrandColors.primaryWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BrandColors.primaryOrange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: BrandColors.primaryOrange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      product.typeLabel,
                      style: const TextStyle(
                        color: BrandColors.primaryOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: BrandColors.primaryWhite.withValues(alpha: 0.85),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (product.storeLinks.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 12),
              decoration: BoxDecoration(
                color: BrandColors.primaryBlack,
                border: Border(
                  top: BorderSide(
                    color: BrandColors.primaryOrange.withValues(alpha: 0.2),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (final link in product.storeLinks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: AppHaptics.wrap(
                            () => _openStore(product, link),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.primaryOrange,
                            foregroundColor: BrandColors.primaryWhite,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Comprar en ${link.label}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCover extends StatelessWidget {
  final Product product;

  const _HeroCover({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.thumbnailUrl != null && product.thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: product.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: BrandColors.grayDark),
              errorWidget: (_, __, ___) => Container(
                color: BrandColors.blackLight,
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: BrandColors.primaryOrange,
                  size: 48,
                ),
              ),
            )
          else
            Container(
              color: BrandColors.blackLight,
              child: const Icon(
                Icons.menu_book_rounded,
                color: BrandColors.primaryOrange,
                size: 48,
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
