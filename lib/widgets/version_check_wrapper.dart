import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';
import '../utils/brand_colors.dart';

class VersionCheckWrapper extends StatefulWidget {
  final Widget child;
  
  const VersionCheckWrapper({
    super.key,
    required this.child,
  });

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper>
    with TickerProviderStateMixin {
  bool _isCheckingVersion = true;
  bool _needsUpdate = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _currentMessageIndex = 0;
  late List<String> _loadingMessages;

  @override
  void initState() {
    super.initState();
    print('🚀 VersionCheckWrapper: initState llamado');
    _setupAnimations();
    _setupLoadingMessages();
    _startMessageRotation();
    _checkVersion();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.repeat(reverse: true);
  }

  void _setupLoadingMessages() {
    _loadingMessages = [
      'Inicializando DevLokos...',
      'Conectando con Firebase...',
      'Verificando configuración...',
      'Preparando contenido...',
      'Cargando episodios...',
      '¡Casi listo!',
    ];
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isCheckingVersion) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkVersion() async {
    try {
      print('🔄 VersionCheckWrapper: Iniciando verificación de versión...');
      
      // Pequeña pausa para asegurar que Remote Config esté listo
      await Future.delayed(const Duration(milliseconds: 500));
      
      final remoteConfig = RemoteConfigService();
      
      print('🔍 VersionCheckWrapper: Verificando configuración de Remote Config...');
      final isConfigured = remoteConfig.isRemoteConfigConfigured;
      print('   - Remote Config configurado: $isConfigured');
      
      print('🔍 VersionCheckWrapper: Obteniendo información de versión...');
      final currentVersion = remoteConfig.currentVersion;
      final minimumVersion = remoteConfig.minimumRequiredVersion;
      final needsUpdate = remoteConfig.needsUpdate;
      
      print('📊 VersionCheckWrapper: Información de versiones:');
      print('   - Versión actual: $currentVersion');
      print('   - Versión mínima requerida: $minimumVersion');
      print('   - ¿Necesita actualización? $needsUpdate');
      
      // Verificar si necesita actualización basado en Remote Config
      final finalNeedsUpdate = needsUpdate;
      
      if (finalNeedsUpdate) {
        print('🚨 VersionCheckWrapper: ACTUALIZACIÓN REQUERIDA: La versión remota es mayor que la actual');
      } else {
        print('✅ VersionCheckWrapper: No se requiere actualización');
      }
      
      setState(() {
        _needsUpdate = finalNeedsUpdate;
        _isCheckingVersion = false;
      });
      
      if (_needsUpdate) {
        print('🚨 VersionCheckWrapper: ACTUALIZACIÓN REQUERIDA DETECTADA');
        print('   - Versión actual: $currentVersion');
        print('   - Versión mínima: $minimumVersion');
        print('   - Se mostrará la alerta de actualización');
      } else {
        print('✅ VersionCheckWrapper: Versión actual es compatible, no se requiere actualización');
      }
    } catch (e) {
      print('❌ VersionCheckWrapper: Error al verificar versión: $e');
      setState(() {
        _needsUpdate = false; // En caso de error, permitir continuar
        _isCheckingVersion = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 VersionCheckWrapper build - _isCheckingVersion: $_isCheckingVersion, _needsUpdate: $_needsUpdate');
    
    // Si necesita actualización, no mostrar loading, ir directo a la app con alerta
    if (_needsUpdate) {
      print('🚨 VersionCheckWrapper: Necesita actualización, mostrando app con alerta...');
      // Usar un Future.delayed para asegurar que el contexto esté listo
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          print('📱 VersionCheckWrapper: Mostrando alerta de actualización...');
          _showUpdateAlert(context);
        }
      });
      return widget.child;
    }
    
    // Mostrar loading solo si está verificando y NO necesita actualización
    if (_isCheckingVersion) {
      print('⏳ VersionCheckWrapper: Mostrando pantalla de carga...');
      return _buildDynamicLoadingScreen();
    }
    
    print('✅ VersionCheckWrapper: No necesita actualización, continuando normalmente');
    
    // Siempre mostrar la aplicación normal
    return widget.child;
  }

      void _showUpdateAlert(BuildContext context) {
        print('🚨 _showUpdateAlert llamado - mostrando diálogo de actualización');
        final remoteConfig = RemoteConfigService();
        
        showDialog(
          context: context,
          barrierDismissible: false, // No se puede cerrar tocando fuera
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false, // No se puede cerrar con botón back
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
                  Container(
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
            );
          },
        );
      }

  Future<void> _launchUpdateUrl() async {
    try {
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

  Widget _buildDynamicLoadingScreen() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: const Color(0xFFFF914D).withOpacity(_fadeAnimation.value),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF914D).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(57),
                        child: Image.asset(
                          'assets/icons/devlokos_icon.png',
                          width: 114,
                          height: 114,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              
              // Indicador de progreso personalizado
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _fadeAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF914D),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF914D).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              
              // Mensaje dinámico
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _loadingMessages[_currentMessageIndex],
                  key: ValueKey(_currentMessageIndex),
                  style: const TextStyle(
                    color: Color(0xFFFF914D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              
              // Indicador de puntos animados
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final animationValue = (_animationController.value + delay) % 1.0;
                      final opacity = (1.0 - (animationValue * 2).clamp(0.0, 1.0));
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF914D).withOpacity(opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 40),
              
              // Texto secundario
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Preparando la mejor experiencia de podcast para ti',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}