import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/brand_colors.dart';
import '../services/remote_config_service.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    
    return PopScope(
      canPop: false, // Evitar que el usuario pueda salir
      child: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de la app
                Container(
                  width: 120,
                  height: 120,
              decoration: BoxDecoration(
                color: BrandColors.primaryBlack,
                borderRadius: BorderRadius.circular(60),
              ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(57),
                    child: Image.asset(
                      'assets/icons/devlokos_icon.webp',
                      width: 114,
                      height: 114,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Título principal
                Text(
                  '¡Nueva Versión Disponible!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: BrandColors.primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Mensaje descriptivo
                Text(
                  'Hemos lanzado una nueva versión de DevLokos con mejoras importantes y nuevas funcionalidades.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BrandColors.grayMedium,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Información de versiones
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BrandColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrandColors.primaryOrange,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Versión actual:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BrandColors.grayMedium,
                            ),
                          ),
                          Text(
                            remoteConfig.currentVersion,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BrandColors.primaryWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nueva versión:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BrandColors.grayMedium,
                            ),
                          ),
                          Text(
                            remoteConfig.minimumRequiredVersion,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BrandColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botón de actualización
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _launchAppStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.primaryOrange,
                      foregroundColor: BrandColors.primaryWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.download,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Actualizar Ahora',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BrandColors.primaryWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Mensaje adicional
                Text(
                  'Para continuar usando DevLokos, necesitas actualizar a la última versión.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BrandColors.grayMedium,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Lanzar la tienda de aplicaciones
  Future<void> _launchAppStore() async {
    try {
      // Usar Onelink.to para redirección automática a la tienda correcta
      const url = 'https://onelink.to/DevLokos';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('❌ No se pudo abrir la URL de actualización');
      }
    } catch (e) {
      print('❌ Error al abrir la URL de actualización: $e');
    }
  }
}
