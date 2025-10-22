import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/brand_colors.dart';
import '../config/environment_config.dart';
import '../utils/user_manager.dart';
import '../constants/app_constants.dart';

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
      // 1. Verificar si hay un usuario guardado localmente
      final hasLocalUser = await UserManager.hasUser();
      
      if (hasLocalUser) {
        // Si hay usuario local, verificar si existe en Firestore
        final localUser = await UserManager.getUser();
        if (localUser != null) {
          final existsInFirestore = await _checkUserExistsInFirestore(localUser.uid);
          
          if (existsInFirestore) {
            // Usuario existe en Firestore, ir a home
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
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null) {
        // Hay usuario en Firebase Auth, verificar en Firestore
        final existsInFirestore = await _checkUserExistsInFirestore(firebaseUser.uid);
        
        if (existsInFirestore) {
          // Usuario existe en Firestore, guardar localmente y ir a home
          final userModel = UserModel.fromFirebaseUser(firebaseUser);
          await UserManager.saveUser(userModel);
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
          .doc(uid)
          .get();
      
      return doc.exists && doc.data() != null;
    } catch (e) {
      print('Error al verificar usuario en Firestore: $e');
      return false;
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
