import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import '../../repository/products_repository.dart';
import '../../services/analytics_service.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/content_skeleton.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/section_header.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with AutomaticKeepAliveClientMixin {
  final ProductsRepository _repository = ProductsRepositoryImpl();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logProductsViewed();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _repository.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openUrl(Product product, ProductStoreLink link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) return;
    await AnalyticsService.logProductStoreClicked(
      productId: product.id,
      storeLabel: link.label,
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: const CustomAppBar(title: ''),
      body: SafeArea(
        child: RefreshIndicator(
          color: BrandColors.primaryOrange,
          backgroundColor: BrandColors.cardBackground,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    'Libros y productos digitales de DevLokos para impulsar tu carrera.',
                    style: TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Productos',
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ContentSkeleton.card(count: 2),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorState(
                    message: _error!,
                    onRetry: _load,
                  ),
                )
              else if (_products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Pronto habrá productos',
                    subtitle: 'Estamos preparando el catálogo. Vuelve en breve.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _ProductCard(
                        product: _products[index],
                        onOpenLink: _openUrl,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final Future<void> Function(Product product, ProductStoreLink link) onOpenLink;

  const _ProductCard({
    required this.product,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.thumbnailUrl != null && product.thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: product.thumbnailUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 180,
                color: BrandColors.grayDark,
              ),
              errorWidget: (_, __, ___) => Container(
                height: 180,
                color: BrandColors.grayDark,
                child: const Icon(Icons.menu_book, color: BrandColors.grayMedium),
              ),
            )
          else
            Container(
              height: 180,
              color: BrandColors.grayDark,
              child: const Center(
                child: Icon(Icons.menu_book, color: BrandColors.grayMedium, size: 48),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product.typeLabel,
                    style: const TextStyle(
                      color: BrandColors.primaryOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: const TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                if (product.storeLinks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.storeLinks.map((link) {
                      return ElevatedButton(
                        onPressed: () => onOpenLink(product, link),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.primaryOrange,
                          foregroundColor: BrandColors.primaryWhite,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(link.label),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
