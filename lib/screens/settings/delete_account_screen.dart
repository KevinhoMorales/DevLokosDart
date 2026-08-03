import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/auth/auth_bloc_exports.dart';
import '../../services/biometric_service.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _busy = false;

  static const _risks = <({IconData icon, String title, String subtitle})>[
    (
      icon: Icons.person_off_outlined,
      title: 'Tu perfil se borrará',
      subtitle: 'Nombre, bio, empresa, rol y foto de perfil.',
    ),
    (
      icon: Icons.link_off_rounded,
      title: 'Redes y datos asociados',
      subtitle: 'Enlaces sociales y preferencias guardadas en tu cuenta.',
    ),
    (
      icon: Icons.lock_outline_rounded,
      title: 'Perderás el acceso',
      subtitle: 'No podrás entrar con este correo salvo que crees una cuenta nueva.',
    ),
    (
      icon: Icons.warning_amber_rounded,
      title: 'Acción irreversible',
      subtitle: 'Una vez eliminada, no podremos recuperar tu información.',
    ),
  ];

  Future<void> _onDeletePressed() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          '¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer.',
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
              'Eliminar',
              style: TextStyle(
                color: BrandColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final bioAvailable = await _biometricService.isAvailable();
      if (bioAvailable) {
        final ok = await _biometricService.authenticate(
          reason: 'Confirma con biometría para eliminar tu cuenta',
        );
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Autenticación biométrica cancelada o fallida.'),
                backgroundColor: BrandColors.error,
              ),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      await _showPasswordDialog();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
              'Por seguridad, ingresa tu contraseña actual para completar la eliminación.',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
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
              onSubmitted: (_) {
                if (passwordController.text.isNotEmpty) {
                  Navigator.of(ctx).pop(true);
                }
              },
            ),
          ],
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
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text(
              'Eliminar cuenta',
              style: TextStyle(
                color: BrandColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    final password = passwordController.text;
    passwordController.dispose();

    if (confirmed == true && password.isNotEmpty && mounted) {
      context.read<AuthBlocSimple>().add(
            AuthDeleteAccountWithReauthRequested(password: password),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: BrandColors.error,
            ),
          );
          context.read<AuthBlocSimple>().add(const AuthErrorCleared());
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(
          title: 'Eliminar cuenta',
          showBackButton: true,
        ),
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<AuthBlocSimple, AuthState>(
            builder: (context, state) {
              final loading = state is AuthLoading || _busy;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: BrandColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BrandColors.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: BrandColors.error,
                            size: 26,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Esta acción es permanente',
                                  style: TextStyle(
                                    color: BrandColors.primaryWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Antes de continuar, revisa qué se eliminará de tu cuenta DevLokos.',
                                  style: TextStyle(
                                    color: BrandColors.grayMedium,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._risks.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: BrandColors.blackLight.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: BrandColors.primaryOrange.withValues(
                                alpha: 0.16,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: BrandColors.primaryOrange.withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  r.icon,
                                  color: BrandColors.primaryOrange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      style: const TextStyle(
                                        color: BrandColors.primaryWhite,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      r.subtitle,
                                      style: const TextStyle(
                                        color: BrandColors.grayMedium,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : AppHaptics.wrap(_onDeletePressed),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrandColors.error,
                          side: const BorderSide(color: BrandColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: BrandColors.error,
                                ),
                              )
                            : const Text(
                                'ELIMINAR MI CUENTA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
