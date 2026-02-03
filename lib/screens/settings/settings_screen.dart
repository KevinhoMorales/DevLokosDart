import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/auth/auth_bloc_exports.dart';
import '../../constants/app_constants.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/push_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  bool _notificationsEnabled = false;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _checkNotificationStatus();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final fromPackage = '${packageInfo.version}+${packageInfo.buildNumber}';
      // Usar la versión de package_info; si no coincide con la constante, priorizar la constante
      // (evita mostrar versión antigua por build cache)
      setState(() {
        _appVersion = fromPackage == AppConstants.appVersionWithBuild
            ? fromPackage
            : AppConstants.appVersionWithBuild;
      });
    } catch (_) {
      setState(() => _appVersion = AppConstants.appVersionWithBuild);
    }
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final enabled = await PushNotificationService().areNotificationsEnabled();
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          _isLoadingNotifications = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  Future<void> _onNotificationsChanged(bool value) async {
    if (value) {
      final granted = await PushNotificationService().requestNotificationPermission();
      if (mounted) setState(() => _notificationsEnabled = granted);
    } else {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: BrandColors.blackLight,
            title: const Text(
              'Desactivar notificaciones',
              style: TextStyle(color: BrandColors.primaryWhite),
            ),
            content: const Text(
              'Para desactivar las notificaciones, ve a la configuración de tu dispositivo.',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Entendido',
                  style: TextStyle(color: BrandColors.primaryOrange),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
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
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          }
        },
        child: Scaffold(
          appBar: const CustomAppBar(
            title: 'Ajustes',
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
                  children: [
                    _buildNotificationsSection(),
                    const SizedBox(height: 24),
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                    const SizedBox(height: 16),
                    _buildTermsSection(),
                    const SizedBox(height: 16),
                    _buildPrivacySection(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    const SizedBox(height: 16),
                    _buildDeleteButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
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
            child: const Icon(
              Icons.notifications_outlined,
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
                  'Notificaciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: BrandColors.primaryWhite,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _notificationsEnabled ? 'Activadas' : 'Desactivadas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BrandColors.grayMedium,
                      ),
                ),
              ],
            ),
          ),
          if (_isLoadingNotifications)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
                strokeWidth: 2,
              ),
            )
          else
            Switch.adaptive(
              value: _notificationsEnabled,
              onChanged: _onNotificationsChanged,
              activeTrackColor: BrandColors.primaryOrange.withOpacity(0.5),
              activeThumbColor: BrandColors.primaryOrange,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
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
            child: const Icon(
              Icons.info_outline,
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
                  'Versión',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: BrandColors.primaryWhite,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _appVersion,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BrandColors.grayMedium,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return GestureDetector(
      onTap: () => context.push('/settings/about'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: BrandColors.blackLight.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BrandColors.primaryOrange.withOpacity(0.2),
          ),
          boxShadow: BrandColors.blackShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
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
                      'Acerca de DevLokos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BrandColors.primaryWhite,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Conoce nuestra historia',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BrandColors.grayMedium,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: BrandColors.grayMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return _buildLegalLinkSection(
      title: 'Términos y condiciones',
      subtitle: 'Consulta los términos de uso',
      icon: Icons.description_outlined,
      url: AppConstants.termsAndConditionsUrl,
    );
  }

  Widget _buildPrivacySection() {
    return _buildLegalLinkSection(
      title: 'Política de privacidad',
      subtitle: 'Cómo protegemos tus datos',
      icon: Icons.privacy_tip_outlined,
      url: AppConstants.privacyPolicyUrl,
    );
  }

  Widget _buildLegalLinkSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: BrandColors.blackLight.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BrandColors.primaryOrange.withOpacity(0.2),
          ),
          boxShadow: BrandColors.blackShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BrandColors.primaryWhite,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BrandColors.grayMedium,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: BrandColors.grayMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede abrir el enlace'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir: $e'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    }
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: BrandColors.primaryOrange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrandColors.primaryOrange),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: BrandColors.primaryOrange, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Cerrar sesión',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: BrandColors.primaryOrange,
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

  Widget _buildDeleteButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDeleteAccountDialog,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Eliminar cuenta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: BrandColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: BrandColors.primaryOrange, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      context.read<AuthBlocSimple>().add(const AuthLogoutRequested());
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          'Esta acción es irreversible. Se eliminarán todos tus datos, incluyendo tu perfil, imágenes y datos asociados. Para confirmar, necesitas ingresar tu contraseña.',
          style: TextStyle(color: BrandColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Continuar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      _showPasswordDialog();
    }
  }

  void _showPasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Confirmar contraseña',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu contraseña actual para confirmar la eliminación:',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: BrandColors.primaryWhite),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(color: BrandColors.grayMedium),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BrandColors.grayMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BrandColors.primaryOrange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (passwordController.text.isNotEmpty && mounted) {
                context.read<AuthBlocSimple>().add(
                      AuthDeleteAccountWithReauthRequested(
                        password: passwordController.text,
                      ),
                    );
              }
            },
            child: const Text(
              'Eliminar cuenta',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
