import 'package:flutter/widgets.dart';

/// Breakpoints y helpers de layout para tablet / iPad / desktop-like.
class Responsive {
  Responsive._();

  static const double tabletShortestSide = 600;
  static const double wideWidth = 900;
  static const double phoneMaxWidth = 720;
  static const double tabletMaxWidth = 1100;

  static Size _size(BuildContext context) => MediaQuery.sizeOf(context);

  /// Tablet o mayor (`shortestSide >= 600`).
  static bool isTablet(BuildContext context) =>
      _size(context).shortestSide >= tabletShortestSide;

  /// Ancho generoso (iPad landscape / desktop-like).
  static bool isWide(BuildContext context) =>
      _size(context).width >= wideWidth;

  /// Tope de contenido centrado.
  static double contentMaxWidth(BuildContext context) =>
      isTablet(context) ? tabletMaxWidth : phoneMaxWidth;

  /// Padding horizontal del contenido.
  static double horizontalPadding(BuildContext context) =>
      isTablet(context) ? 32 : 20;

  /// Padding exterior del buscador — mismo en Podcast / Tutoriales / Academia
  /// para que no “salte” al cambiar de tab.
  static EdgeInsets searchBarPadding(BuildContext context) {
    final h = horizontalPadding(context);
    return EdgeInsets.fromLTRB(h, 12, h, 12);
  }

  /// Columnas para listas densas de episodios.
  static int episodeCrossAxisCount(BuildContext context) =>
      isTablet(context) ? 2 : 1;

  /// Columnas del grid de portafolio: phone 2 · tablet 3 · wide 4.
  static int portfolioCrossAxisCount(BuildContext context) {
    final w = _size(context).width;
    if (w >= 1100) return 4;
    if (w >= 700 || isTablet(context)) return 3;
    return 2;
  }

  /// Relación ancho/alto de cada card de portafolio.
  static double portfolioChildAspectRatio(BuildContext context) {
    final cols = portfolioCrossAxisCount(context);
    if (cols >= 4) return 0.82;
    if (cols == 3) return 0.78;
    return 0.70;
  }

  static double portfolioGap(BuildContext context) =>
      isTablet(context) ? 16 : 12;
}
