import 'package:flutter/material.dart';
import '../utils/brand_colors.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final double? width;
  final double height;
  final LinearGradient? gradient;
  final Color? textColor;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.gradient,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null && !isLoading
            ? (gradient ?? BrandColors.primaryGradient)
            : const LinearGradient(
                colors: [
                  BrandColors.grayMedium,
                  BrandColors.grayMedium,
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null && !isLoading
            ? BrandColors.orangeShadow
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          enableFeedback: false,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          textColor ?? BrandColors.primaryWhite,
                        ),
                      ),
                    )
                  : Text(
                      text.toUpperCase(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor ?? BrandColors.primaryWhite,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
