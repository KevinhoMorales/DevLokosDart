import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Feedback háptico unificado para acciones de la app.
class AppHaptics {
  AppHaptics._();

  /// Tap / botón / card (impacto ligero).
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Cambio de tab, chip, switch o selector.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Acción importante (confirmar, activar notificaciones, etc.).
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Envuelve un callback de tap con haptic ligero.
  static VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      light();
      callback();
    };
  }

  /// Envuelve un callback de selección (tabs, switches, filtros).
  static VoidCallback? wrapSelection(VoidCallback? callback) {
    if (callback == null) return null;
    return () {
      selection();
      callback();
    };
  }

  static ValueChanged<T>? wrapChanged<T>(ValueChanged<T>? callback) {
    if (callback == null) return null;
    return (value) {
      selection();
      callback(value);
    };
  }

  static ValueChanged<T>? wrapChangedLight<T>(ValueChanged<T>? callback) {
    if (callback == null) return null;
    return (value) {
      light();
      callback(value);
    };
  }

  /// Splash Material con haptic: cubre InkWell, IconButton, TextButton, etc.
  static const InteractiveInkFeatureFactory splashFactory =
      _HapticSplashFactory();
}

class _HapticSplashFactory extends InteractiveInkFeatureFactory {
  const _HapticSplashFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    AppHaptics.light();
    return InkRipple(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
