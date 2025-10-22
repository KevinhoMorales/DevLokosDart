import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/auth/auth_bloc_exports.dart';
import '../utils/brand_colors.dart';
import '../utils/login_helper.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

class RegisterBottomSheet extends StatefulWidget {
  const RegisterBottomSheet({super.key});

  @override
  State<RegisterBottomSheet> createState() => _RegisterBottomSheetState();
}

class _RegisterBottomSheetState extends State<RegisterBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      context.read<AuthBlocSimple>().add(
        AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        ),
      );
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes aceptar los términos y condiciones'),
          backgroundColor: BrandColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 85% de la pantalla
      decoration: const BoxDecoration(
        color: BrandColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildRegisterForm(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: BrandColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar bottom sheet actual
              LoginHelper.showLoginBottomSheet(context); // Mostrar login bottom sheet
            },
            icon: const Icon(
              Icons.arrow_back,
              color: BrandColors.primaryWhite,
              size: 24,
            ),
          ),
          const Expanded(
            child: Text(
              'Crear Cuenta',
              style: TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance para centrar el título
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo DevLokos oficial
        ScaleTransition(
          scale: _logoScaleAnimation,
          child: Container(
            width: 120,
            height: 90,
            decoration: BoxDecoration(
              color: BrandColors.primaryBlack,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/icons/devlokos_icon.png',
                width: 100,
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Únete a DevLokos!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: BrandColors.primaryWhite,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return BlocConsumer<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterSuccess || state is AuthAuthenticated) {
          // Cerrar el bottom sheet al registrarse exitosamente
          Navigator.of(context).pop();
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
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: BrandColors.blackLight.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BrandColors.primaryOrange.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: BrandColors.blackShadow,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Nombre completo',
                  hintText: 'Nombre y apellido',
                  prefixIcon: Icons.person_outlined,
                  textColor: BrandColors.primaryWhite,
                  borderColor: BrandColors.primaryOrange,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    if (value.length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Correo electrónico',
                  hintText: 'info@devlokos.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textColor: BrandColors.primaryWhite,
                  borderColor: BrandColors.primaryOrange,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo electrónico';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Por favor ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  hintText: '********',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  textColor: BrandColors.primaryWhite,
                  borderColor: BrandColors.primaryOrange,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: BrandColors.grayMedium,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirmar contraseña',
                  hintText: '********',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outlined,
                  textColor: BrandColors.primaryWhite,
                  borderColor: BrandColors.primaryOrange,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: BrandColors.grayMedium,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTermsCheckbox(),
                const SizedBox(height: 24),
                if (state is AuthLoading)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: BrandColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          BrandColors.primaryWhite,
                        ),
                      ),
                    ),
                  )
                else
                  GradientButton(
                    onPressed: _handleRegister,
                    text: 'Crear Cuenta',
                    gradient: BrandColors.primaryGradient,
                    textColor: BrandColors.primaryWhite,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: BrandColors.primaryOrange,
          checkColor: BrandColors.primaryWhite,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BrandColors.grayMedium,
                ),
                children: [
                  const TextSpan(text: 'Acepto los '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => _openTermsAndConditions(),
                      child: const Text(
                        'términos y condiciones',
                        style: TextStyle(
                          color: BrandColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: BrandColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' y la '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => _openPrivacyPolicy(),
                      child: const Text(
                        'política de privacidad',
                        style: TextStyle(
                          color: BrandColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: BrandColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openTermsAndConditions() async {
    const url = 'https://kevinhomorales.super.site/play-store/devlokos';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el enlace: $e'),
            backgroundColor: BrandColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _openPrivacyPolicy() async {
    const url = 'https://kevinhomorales.super.site/play-store/devlokos';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el enlace: $e'),
            backgroundColor: BrandColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

}
