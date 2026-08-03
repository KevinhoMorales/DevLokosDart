import 'package:flutter/material.dart';

/// Resuelve el icono de un servicio a [IconData] (sin emojis en UI).
IconData serviceIconData(String? raw) {
  final key = (raw ?? '').trim().toLowerCase();
  if (key.isEmpty) return Icons.business_center_outlined;

  switch (key) {
    case 'code':
    case 'laptop':
    case 'computer':
    case 'software':
    case '💻':
      return Icons.code_rounded;
    case 'phone':
    case 'mobile':
    case 'smartphone':
    case 'phone_iphone':
    case '📱':
      return Icons.phone_iphone_rounded;
    case 'consulting':
    case 'compass':
    case 'explore':
    case '🧭':
      return Icons.explore_outlined;
    case 'web':
    case 'language':
    case '🌐':
      return Icons.language_rounded;
    case 'cloud':
    case '☁️':
    case '☁':
      return Icons.cloud_outlined;
    case 'security':
    case 'lock':
    case '🔒':
      return Icons.lock_outline_rounded;
    case 'build':
    case 'handyman':
    case '🛠️':
    case '🛠':
      return Icons.build_outlined;
    case 'rocket':
    case '🚀':
      return Icons.rocket_launch_outlined;
    case 'business':
    case 'briefcase':
    case 'business_center':
    case '💼':
      return Icons.business_center_outlined;
    case 'design':
    case 'palette':
      return Icons.palette_outlined;
    case 'analytics':
    case 'chart':
      return Icons.insights_outlined;
    default:
      // Si Firestore guardó un emoji u otro valor desconocido, icono neutro.
      if (_looksLikeEmoji(raw!)) {
        return Icons.business_center_outlined;
      }
      return Icons.business_center_outlined;
  }
}

bool _looksLikeEmoji(String value) {
  // Heurística simple: caracteres fuera de ASCII básico / nombres de icono.
  return !RegExp(r'^[a-z0-9_]+$', caseSensitive: false).hasMatch(value.trim());
}
