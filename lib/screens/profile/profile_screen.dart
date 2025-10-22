import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc_exports.dart';
import '../../utils/brand_colors.dart';
import '../../utils/user_manager.dart';
import '../../utils/login_helper.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserManager.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navegar a la pantalla de home cuando se cierre sesión
          context.go('/home');
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
            _navigateToHome();
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'Mi Perfil',
            showBackButton: true,
            actions: [
              IconButton(
                onPressed: _openSettings,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513), // Color marrón oscuro
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.info,
                    color: BrandColors.primaryOrange,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: BrandColors.primaryBlack,
            ),
            child: SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          BrandColors.primaryOrange,
                        ),
                      ),
                    )
                  : _buildContent(),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildContent() {
    if (_currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              size: 64,
              color: BrandColors.grayMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay información de usuario',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: BrandColors.primaryWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor, inicia sesión para acceder a tu perfil',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.grayMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => LoginHelper.showLoginBottomSheet(context),
              icon: const Icon(Icons.login),
              label: const Text('Iniciar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primaryOrange,
                foregroundColor: BrandColors.primaryWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar Section
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: BrandColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: BrandColors.primaryOrange.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: BrandColors.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // User Information Cards
          _buildInfoCard(
            title: 'Nombre',
            value: _currentUser!.displayName ?? 'No especificado',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            title: 'Correo Electrónico',
            value: _currentUser!.email,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            title: 'ID de Usuario',
            value: _currentUser!.uid,
            icon: Icons.fingerprint,
            isUid: true,
          ),
          const SizedBox(height: 32),

          // Actions
          _buildActionButton(
            title: 'Cerrar Sesión',
            icon: Icons.logout,
            onTap: () => _showLogoutDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isUid = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: BrandColors.blackShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: BrandColors.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BrandColors.grayMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BrandColors.primaryWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: isUid ? 12 : 16,
                  ),
                  maxLines: isUid ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    if (isDestructive) {
      // Botón destructivo con estilo similar a login/register pero rojo
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
                title.toUpperCase(),
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
    
    // Botón normal (no destructivo) - mantener el estilo original
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.3),
          width: 1,
        ),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: BrandColors.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BrandColors.primaryWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
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
              'Cerrar Sesión',
              style: TextStyle(color: BrandColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Usar AuthBloc para cerrar sesión
      context.read<AuthBlocSimple>().add(const AuthLogoutRequested());
    }
  }

  void _navigateToHome() {
    // Navegar a la home con los tabs
    context.go('/home');
  }

  void _openSettings() {
    context.go('/settings');
  }
}

