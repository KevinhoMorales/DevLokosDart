import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';
import '../utils/brand_colors.dart';

/// Wrapper que verifica la versión de la app en segundo plano.
/// Muestra la app directamente (el launch nativo ya cubre la carga inicial).
class VersionCheckWrapper extends StatefulWidget {
  final Widget child;

  const VersionCheckWrapper({
    super.key,
    required this.child,
  });

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  bool _alertShown = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final remoteConfig = RemoteConfigService();
      final needsUpdate = remoteConfig.needsUpdate;

      if (mounted && needsUpdate && !_alertShown) {
        _alertShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showUpdateAlert(context);
        });
      }
    } catch (_) {
      // En caso de error, permitir continuar sin bloquear
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _showUpdateAlert(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: BrandColors.cardBackground,
          title: const Text(
            'ACTUALIZACIÓN REQUERIDA',
            style: TextStyle(
              color: BrandColors.primaryWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Una nueva versión de DevLokos está disponible.\n\nVersión actual: ${remoteConfig.currentVersion}\nNueva versión: ${remoteConfig.minimumRequiredVersion}\n\nPara continuar usando la aplicación, necesitas actualizar ahora.',
            style: const TextStyle(
              color: BrandColors.grayLight,
              fontSize: 14,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _launchUpdateUrl(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primaryOrange,
                  foregroundColor: BrandColors.primaryWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ACTUALIZAR AHORA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUpdateUrl() async {
    try {
      const url = 'https://onelink.to/DevLokos';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}