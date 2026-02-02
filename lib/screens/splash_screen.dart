import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/brand_colors.dart';
import '../config/environment_config.dart';
import '../utils/user_manager.dart';
import '../constants/app_constants.dart';
import '../services/remote_config_service.dart';
import '../services/user_firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
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
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      await _checkUserAndNavigate();
    }
  }

  Future<void> _checkUserAndNavigate() async {
    try {
      // 0. Verificar versión primero
      print('🔄 SplashScreen: Verificando versión...');
      final remoteConfig = RemoteConfigService();
      final needsUpdate = remoteConfig.needsUpdate;
      
      print('📊 SplashScreen: Información de versiones:');
      print('   - Versión actual: ${remoteConfig.currentVersion}');
      print('   - Versión mínima requerida: ${remoteConfig.minimumRequiredVersion}');
      print('   - ¿Necesita actualización? $needsUpdate');
      
      if (needsUpdate) {
        print('🚨 SplashScreen: ACTUALIZACIÓN REQUERIDA - Mostrando alerta');
        _showUpdateAlert();
        return; // No continuar con la navegación si necesita actualización
      }
      
      print('✅ SplashScreen: Versión OK, continuando con navegación...');
      
      // 1. Verificar si hay un usuario guardado localmente
      final hasLocalUser = await UserManager.hasUser();
      
      if (hasLocalUser) {
        // Si hay usuario local, verificar Firebase Auth y que el email esté verificado
        final localUser = await UserManager.getUser();
        if (localUser != null) {
          var firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            await firebaseUser.reload();
            firebaseUser = FirebaseAuth.instance.currentUser;
            if (firebaseUser == null || !firebaseUser.emailVerified) {
              await FirebaseAuth.instance.signOut();
              await UserManager.deleteUser();
              context.go('/home');
              return;
            }
          }
          final existsInFirestore = await _checkUserExistsInFirestore(localUser.uid);
          
          if (existsInFirestore) {
            // Usuario existe en Firestore: sincronizar y sobrescribir si hay cambios
            await UserManager.syncUserOnAppStart();
            context.go('/home');
            return;
          } else {
            // Usuario no existe en Firestore, limpiar local y ir a home (sin login)
            await UserManager.deleteUser();
            context.go('/home');
            return;
          }
        }
      }

      // 2. Si no hay usuario local, verificar Firebase Auth
      var firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null) {
        // Verificar que el email esté verificado
        await firebaseUser.reload();
        firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null || !firebaseUser.emailVerified) {
          await FirebaseAuth.instance.signOut();
          context.go('/home');
          return;
        }
        
        // Hay usuario en Firebase Auth, verificar en Firestore
        final existsInFirestore = await _checkUserExistsInFirestore(firebaseUser!.uid);
        
        if (existsInFirestore) {
          // Obtener datos completos desde Firestore (nombre, foto, etc.)
          final firestoreUser = await UserFirestoreService.getUserFromFirestoreByUid(firebaseUser.uid);
          if (firestoreUser != null) {
            await UserManager.saveUser(firestoreUser);
            print('✅ Splash: Usuario cargado desde Firestore y guardado en UserManager');
          } else {
            // Fallback: datos básicos de Firebase Auth
            await UserManager.saveUser(UserModel.fromFirebaseUser(firebaseUser));
            print('⚠️ Splash: Usando datos básicos de Firebase Auth (Firestore no respondió)');
          }
          context.go('/home');
          return;
        } else {
          // Usuario no existe en Firestore, cerrar sesión y ir a home (sin login)
          await FirebaseAuth.instance.signOut();
          context.go('/home');
          return;
        }
      }

      // 3. No hay usuario en ningún lado, ir a home (sin login)
      context.go('/home');
      
    } catch (e) {
      // En caso de error, ir a home por seguridad
      print('Error en _checkUserAndNavigate: $e');
      context.go('/home');
    }
  }

  Future<bool> _checkUserExistsInFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(EnvironmentConfig.getUsersCollectionPath())
          .doc(EnvironmentConfig.getUsersCollectionPath())
          .collection("users")
          .doc(uid)
          .get();
      
      return doc.exists && doc.data() != null;
    } catch (e) {
      print('Error al verificar usuario en Firestore: $e');
      return false;
    }
  }

  void _showUpdateAlert() {
    print('🚨 SplashScreen: _showUpdateAlert llamado - mostrando diálogo de actualización');
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                             // Logo DevLokos oficial
                             Container(
                               width: 200,
                               height: 200,
                               decoration: BoxDecoration(
                                 color: BrandColors.primaryBlack,
                                 borderRadius: BorderRadius.circular(25),
                               ),
                               child: ClipRRect(
                                 borderRadius: BorderRadius.circular(25),
                                 child: Image.asset(
                                   'assets/icons/devlokos_icon.png',
                                   width: 180,
                                   height: 180,
                                   fit: BoxFit.contain,
                                 ),
                               ),
                             ),
                      const SizedBox(height: 32),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'APRENDE - CREA - CRECE',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: BrandColors.grayMedium,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
