import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/brand_colors.dart';
import '../utils/user_manager.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
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
      title: Text(
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
