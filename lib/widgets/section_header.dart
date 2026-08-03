import 'package:flutter/material.dart';
import '../utils/brand_colors.dart';

/// Encabezado de sección: barra naranja + título (+ acción o contador opcional).
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  /// Si se define, muestra un badge con el número (p. ej. cantidad de ítems).
  final int? count;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.count,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (count != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: BrandColors.primaryOrange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: BrandColors.primaryOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ] else if (trailing != null)
            trailing!,
        ],
      ),
    );
  }
}
