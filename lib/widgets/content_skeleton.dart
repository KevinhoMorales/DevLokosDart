import 'package:flutter/material.dart';
import '../utils/brand_colors.dart';

/// Placeholders de carga on-brand (rails horizontales y listas).
class ContentSkeleton extends StatefulWidget {
  final SkeletonVariant variant;
  final int count;

  const ContentSkeleton({
    super.key,
    this.variant = SkeletonVariant.listTile,
    this.count = 4,
  });

  const ContentSkeleton.rail({super.key, this.count = 3})
      : variant = SkeletonVariant.rail;

  const ContentSkeleton.list({super.key, this.count = 5})
      : variant = SkeletonVariant.listTile;

  const ContentSkeleton.card({super.key, this.count = 3})
      : variant = SkeletonVariant.card;

  @override
  State<ContentSkeleton> createState() => _ContentSkeletonState();
}

enum SkeletonVariant { rail, listTile, card }

class _ContentSkeletonState extends State<ContentSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        switch (widget.variant) {
          case SkeletonVariant.rail:
            return SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.count,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => _block(
                  width: 240,
                  height: 188,
                  radius: 16,
                ),
              ),
            );
          case SkeletonVariant.card:
            // ListView (no shrinkWrap): evita overflow en alturas acotadas.
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.count,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, __) => _block(height: 200, radius: 16),
            );
          case SkeletonVariant.listTile:
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.count,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, __) => Row(
                children: [
                  _block(width: 112, height: 72, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _block(height: 14, radius: 6),
                        const SizedBox(height: 8),
                        _block(width: 120, height: 12, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  Widget _block({
    double? width,
    required double height,
    double radius = 12,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: BrandColors.cardBackground.withValues(alpha: _pulse.value),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
