import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/brand_colors.dart';
import '../utils/user_manager.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
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
    final userName = _currentUser?.displayName;
    String greeting = '¡Hola Usuario!';
    
    if (userName != null && userName.isNotEmpty) {
      // Split del nombre y tomar solo el primer nombre
      final firstName = userName.split(' ').first;
      greeting = '¡Hola $firstName!';
    }
    
    return greeting;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(
                Icons.arrow_back,
                color: BrandColors.primaryWhite,
                size: 24,
              ),
            )
          : null,
      title: Text(
        widget.title == 'Mi Perfil' ? 'Mi Perfil' : _getGreeting(),
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
        // Solo mostrar el icono de perfil si no es la pantalla de perfil
        if (!widget.showBackButton)
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(
              Icons.person,
              color: BrandColors.primaryOrange,
              size: 28,
            ),
          ),
        if (widget.actions != null) ...widget.actions!,
      ],
    );
  }
}
