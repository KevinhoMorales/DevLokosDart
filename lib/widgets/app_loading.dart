import 'package:flutter/material.dart';
import '../utils/brand_colors.dart';

/// Indicador de carga de marca (naranja DevLokos).
class AppLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final String? message;

  const AppLoading({
    super.key,
    this.size = 36,
    this.strokeWidth = 3,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: BrandColors.primaryOrange,
        strokeWidth: strokeWidth,
      ),
    );

    if (message == null) {
      return Center(child: indicator);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
