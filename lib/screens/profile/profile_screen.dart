import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/brand_colors.dart';
import '../../utils/user_manager.dart';
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
    return PopScope(
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
              icon: const Icon(
                Icons.settings,
                color: BrandColors.primaryOrange,
                size: 24,
              ),
            ),
          ],
        ),
        body: Container(
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
              'Por favor, inicia sesión nuevamente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.grayMedium,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive 
              ? Colors.red.withOpacity(0.5)
              : BrandColors.primaryOrange.withOpacity(0.3),
          width: isDestructive ? 2 : 1,
        ),
        color: isDestructive 
            ? Colors.red.withOpacity(0.1)
            : Colors.transparent,
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
                  color: isDestructive 
                      ? Colors.red
                      : BrandColors.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDestructive 
                        ? Colors.red
                        : BrandColors.primaryWhite,
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

    if (shouldLogout == true) {
      // Aquí se puede agregar la lógica de logout si es necesario
      await UserManager.deleteUser();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _navigateToHome() {
    // Navegar a la home con los tabs
    context.go('/home');
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: BrandColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.notifications,
                color: BrandColors.primaryOrange,
              ),
              title: Text(
                'Notificaciones',
                style: TextStyle(color: BrandColors.primaryWhite),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.privacy_tip,
                color: BrandColors.primaryOrange,
              ),
              title: Text(
                'Privacidad',
                style: TextStyle(color: BrandColors.primaryWhite),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.help,
                color: BrandColors.primaryOrange,
              ),
              title: Text(
                'Ayuda',
                style: TextStyle(color: BrandColors.primaryWhite),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.info,
                color: BrandColors.primaryOrange,
              ),
              title: Text(
                'Acerca de',
                style: TextStyle(color: BrandColors.primaryWhite),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: BrandColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }
}

