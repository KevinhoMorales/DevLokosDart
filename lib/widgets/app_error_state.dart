import 'package:flutter/material.dart';
import '../utils/brand_colors.dart';
import 'app_empty_state.dart';

/// Estado de error reutilizable con acción de reintento.
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppErrorState({
    super.key,
    this.title = 'Algo salió mal',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline_rounded,
      title: title,
      subtitle: message,
      showRetry: onRetry != null,
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }
}
