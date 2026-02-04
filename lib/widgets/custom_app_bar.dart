import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth/auth_bloc_exports.dart';
import '../utils/brand_colors.dart';
import '../utils/user_manager.dart';
import '../utils/login_helper.dart';

/// Acción de icono con estilo consistente (cuadrado con esquinas redondeadas).
class AppBarIconAction {
  final IconData icon;
  final void Function(BuildContext context) onTap;
  final String? tooltip;

  const AppBarIconAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final List<AppBarIconAction>? iconActions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.iconActions,
    this.showBackButton = false,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    // Si AuthBloc ya emitió Authenticated antes de montar, cargar usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBlocSimple>().state;
      if (authState is AuthAuthenticated && _currentUser == null) {
        _loadUser();
      }
    });
  }

  Future<void> _loadUser() async {
    final user = await UserManager.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  String _getGreeting() {
    // Mostrar "¡Hola NOMBRE!" si hay usuario autenticado, sino "¡Bienvenido!"
    if (_currentUser != null && _currentUser!.displayName?.isNotEmpty == true) {
      return '¡Hola ${_currentUser!.displayName}!';
    }
    return '¡Bienvenido!';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthRegisterSuccess) {
          // Recargar usuario cuando se autentique o registre
          _loadUser();
        }
      },
      child: AppBar(
        leading: widget.showBackButton
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildAppBarIcon(
                  icon: Icons.arrow_back_rounded,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  tooltip: 'Volver',
                  useAccentColor: false,
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildAppBarIcon(
                  icon: Icons.calendar_month_rounded,
                  onTap: () => context.push('/events'),
                  tooltip: 'Eventos',
                ),
              ),
        title: Text(
          widget.showBackButton ? widget.title : 
          widget.title == 'Mi Perfil' ? 'Mi Perfil' : 
          widget.title == 'Acerca de DevLokos' ? 'Acerca de DevLokos' : 
          _getGreeting(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BrandColors.primaryWhite,
          ),
        ),
        backgroundColor: BrandColors.primaryBlack,
        foregroundColor: BrandColors.primaryWhite,
        elevation: 0,
        actions: [
          if (!widget.showBackButton)
            _buildAppBarIcon(
              icon: Icons.person_rounded,
              onTap: () {
                if (_currentUser != null) {
                  context.push('/profile');
                } else {
                  LoginHelper.showLoginBottomSheet(context);
                }
              },
              tooltip: 'Perfil',
            ),
          if (widget.iconActions != null)
            ...widget.iconActions!.map((ia) {
              return Builder(
                builder: (ctx) => _buildAppBarIcon(
                  icon: ia.icon,
                  onTap: () => ia.onTap(ctx),
                  tooltip: ia.tooltip,
                ),
              );
            }),
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
    );
  }

  static const double _iconSize = 40;
  static const double _innerIconSize = 22;

  Widget _buildAppBarIcon({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool useAccentColor = true,
  }) {
    final iconColor = useAccentColor
        ? BrandColors.primaryOrange
        : BrandColors.primaryWhite;
    final bgColor = useAccentColor
        ? BrandColors.primaryOrange.withValues(alpha: 0.2)
        : BrandColors.grayDark.withValues(alpha: 0.5);

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: _innerIconSize,
          ),
        ),
      ),
    );
  }
}
