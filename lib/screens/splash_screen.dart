import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../utils/brand_colors.dart';
import '../config/environment_config.dart';
import '../utils/user_manager.dart';
import '../services/onboarding_service.dart';
import '../services/remote_config_service.dart';
import '../services/user_firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const double _logoSize = 200;

  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: BrandColors.primaryBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(
        const AssetImage(AppConstants.splashStickerPath),
        context,
      );
    });
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 1800));

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

      // Onboarding solo la primera vez que abren la app
      final onboardingDone = await OnboardingService.isCompleted();
      if (!onboardingDone) {
        if (!mounted) return;
        context.go('/onboarding');
        return;
      }
      
      // 1. Verificar si hay un usuario guardado localmente
      final hasLocalUser = await UserManager.hasUser();
      
      if (hasLocalUser) {
        // Usuario guardado localmente: mantener sesión, sincronizar datos
        final localUser = await UserManager.getUser();
        if (localUser != null) {
          var firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null && firebaseUser.uid == localUser.uid) {
            await firebaseUser.reload();
            firebaseUser = FirebaseAuth.instance.currentUser;
            if (firebaseUser == null || !firebaseUser.emailVerified) {
              await FirebaseAuth.instance.signOut();
              await UserManager.deleteUser();
              context.go('/home');
              return;
            }
          }
          // Sincronizar datos desde Firestore (si falla, mantener datos locales)
          await UserManager.syncUserOnAppStart();
          context.go('/home');
          return;
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
      final url = EnvironmentConfig.onelinkUrl;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      body: ColoredBox(
        color: BrandColors.primaryBlack,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppConstants.splashStickerPath,
                    width: _logoSize,
                    height: _logoSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: _logoSize,
                      height: _logoSize,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BrandColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
