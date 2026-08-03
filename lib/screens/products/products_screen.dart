import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../repository/products_repository.dart';
import '../../services/analytics_service.dart';
import '../../utils/brand_colors.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/content_skeleton.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/section_header.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with AutomaticKeepAliveClientMixin {
  final ProductsRepository _repository = ProductsRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  Timer? _searchAnalyticsDebounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logProductsViewed();
    _load();
  }

  @override
  void dispose() {
    _searchAnalyticsDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  List<Product> get _filteredProducts {
    final q = _normalize(_query);
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return _normalize(p.title).contains(q) ||
          _normalize(p.description).contains(q) ||
          _normalize(p.typeLabel).contains(q) ||
          _normalize(p.type).contains(q);
    }).toList();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
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

  void _onSearchChanged(String _) {
    setState(() {});
    _searchAnalyticsDebounce?.cancel();
    final q = _query;
    if (q.isEmpty) return;
    _searchAnalyticsDebounce = Timer(const Duration(milliseconds: 500), () {
      AnalyticsService.logSearchPerformed(
        query: q,
        module: 'products',
        resultsCount: _filteredProducts.length,
      );
    });
  }

  void _openDetail(Product product) {
    context.push(
      '/products/${product.id}',
      extra: {'product': product},
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filtered = _filteredProducts;
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: const CustomAppBar(title: ''),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: Responsive.searchBarPadding(context),
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Buscar productos...',
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: BrandColors.primaryOrange,
                backgroundColor: BrandColors.cardBackground,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                        padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
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
                          subtitle:
                              'Estamos preparando el catálogo. Vuelve en breve.',
                        ),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No se encontraron productos',
                          subtitle: hasQuery
                              ? 'Búsqueda: "$_query"'
                              : 'Prueba con otro término.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return ProductCard(
                              product: product,
                              onTap: () => _openDetail(product),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
