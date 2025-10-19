import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../bloc/auth/auth_bloc_exports.dart';
import '../../utils/brand_colors.dart';
import '../../utils/user_manager.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navegar a la pantalla de login cuando se elimine la cuenta
          context.go('/login');
        } else if (state is AuthError) {
          // Mostrar error si hay algún problema
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: BrandColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            context.go('/profile');
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'Acerca de DevLokos',
            showBackButton: true,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: BrandColors.primaryBlack,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Acerca de DevLokos
                    _buildAboutSection(),
                    const SizedBox(height: 32),
                    
                    // Información de la aplicación
                    _buildAppInfoSection(),
                    const SizedBox(height: 32),
                    
                    // Acciones destructivas
                    _buildDestructiveActionsSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: BrandColors.blackShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/devlokos_podcast_host.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
  
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'DevLokos es una plataforma de podcast que conecta a desarrolladores de software con contenido educativo, entrevistas y experiencias del mundo tech.',
            style: TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Únete a nuestra comunidad y mantente actualizado con las últimas tendencias en desarrollo de software.',
            style: TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: BrandColors.blackShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: BrandColors.primaryWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Versión', _appVersion),
          const SizedBox(height: 12),
          _buildInfoRow('Desarrollado por', 'DevLokos Enterprise'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: BrandColors.grayMedium,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: BrandColors.primaryWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDestructiveActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón para eliminar cuenta
        _buildDestructiveButton(
          title: 'ELIMINAR CUENTA',
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildDestructiveButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: BrandColors.primaryWhite,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Eliminar Cuenta',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu cuenta permanentemente? Esta acción no se puede deshacer y se perderán todos tus datos.',
          style: TextStyle(color: BrandColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      // Aquí puedes agregar la lógica para eliminar la cuenta
      // Por ahora, solo cerramos sesión
      context.read<AuthBlocSimple>().add(const AuthLogoutRequested());
    }
  }
}
