import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/auth/auth_bloc_exports.dart';
import '../../services/admin_service.dart';
import '../../services/image_storage_service.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../utils/login_helper.dart';
import '../../utils/user_manager.dart';
import '../../widgets/custom_app_bar.dart' show AppBarIconAction, CustomAppBar;
import '../../widgets/section_header.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isSavingField = false;
  bool _isAdmin = false;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _fieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _fieldController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    var user = await UserManager.getUser();
    if (user != null) {
      final synced = await UserManager.syncUserOnAppStart();
      if (synced != null) user = synced;
    }
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final email = _currentUser?.email;
    if (email == null || email.isEmpty) {
      if (mounted) setState(() => _isAdmin = false);
      return;
    }
    try {
      final isAdmin = await AdminService.isEmailAdmin(email);
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (_) {
      if (mounted) setState(() => _isAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/home');
        } else if (state is AuthAuthenticated) {
          _loadUser();
        } else if (state is AuthError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) context.go('/home');
        },
        child: Scaffold(
          backgroundColor: BrandColors.primaryBlack,
          appBar: CustomAppBar(
            title: 'Mi Perfil',
            showBackButton: widget.showBackButton,
            iconActions: [
              AppBarIconAction(
                icon: Icons.settings_rounded,
                onTap: (_) => context.push('/settings'),
                tooltip: 'Ajustes',
              ),
            ],
          ),
          body: SafeArea(
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
      return _buildLoggedOutState();
    }

    final user = _currentUser!;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          const SizedBox(height: 18),
          _buildSocialIconsRow(user),
          const SizedBox(height: 20),
          _buildCompactTile(
            title: 'Editar perfil',
            subtitle: 'Nombre, bio, empresa y rol',
            icon: Icons.edit_outlined,
            onTap: _showEditProfileSheet,
          ),
          const SizedBox(height: 8),
          _buildCompactTile(
            title: 'Redes sociales',
            subtitle: _socialSummary(user),
            icon: Icons.link_rounded,
            onTap: _showEditSocialsSheet,
          ),
          const SizedBox(height: 8),
          _buildCompactTile(
            title: user.email,
            subtitle: user.createdAt != null
                ? 'Cuenta · desde ${DateFormat('MMM yyyy').format(user.createdAt!)}'
                : 'Cuenta y ajustes',
            icon: Icons.manage_accounts_outlined,
            onTap: () => context.push('/settings'),
          ),
          if (_isAdmin) ...[
            const SizedBox(height: 8),
            _buildCompactTile(
              title: 'Admin web',
              subtitle: 'CMS DevLokos',
              icon: Icons.admin_panel_settings_outlined,
              onTap: _openAdminWeb,
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: AppHaptics.wrap(_openEmailApp),
              child: Text(
                'Hecho con 🧡 en Ecuador · info@devlokos.com',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BrandColors.grayMedium,
                      fontSize: 12,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_isSavingField) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.primaryOrange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoggedOutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: BrandColors.primaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 44,
                color: BrandColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Inicia sesión en tu perfil',
              style: TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Guarda tu foto, bio y redes para que la comunidad te conozca.',
              style: TextStyle(color: BrandColors.grayMedium, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => LoginHelper.showLoginBottomSheet(context),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Iniciar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primaryOrange,
                  foregroundColor: BrandColors.primaryWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => LoginHelper.showRegisterBottomSheet(context),
              child: const Text(
                'Crear cuenta',
                style: TextStyle(
                  color: BrandColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    final name = (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'Tu perfil';
    final subtitle = [
      if (user.role != null && user.role!.trim().isNotEmpty) user.role!.trim(),
      if (user.company != null && user.company!.trim().isNotEmpty)
        user.company!.trim(),
    ].join(' · ');

    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingImage
              ? null
              : AppHaptics.wrap(_showImagePickerOptions),
          child: Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BrandColors.primaryOrange.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: user.photoURL != null && user.photoURL!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.photoURL!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BrandColors.primaryOrange,
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: BrandColors.primaryOrange,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 42,
                        color: BrandColors.primaryOrange,
                      ),
              ),
              if (_isUploadingImage)
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BrandColors.primaryOrange,
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: BrandColors.primaryOrange,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: BrandColors.primaryBlack,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: BrandColors.primaryWhite,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: BrandColors.primaryWhite,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _socialSummary(UserModel user) {
    final count = [
      user.instagram,
      user.linkedin,
      user.twitter,
      user.github,
      user.tiktok,
      user.website,
    ].where((v) => v != null && v.trim().isNotEmpty).length;
    if (count == 0) return 'Agrega Instagram, GitHub y más';
    return '$count enlace${count == 1 ? '' : 's'} configurado${count == 1 ? '' : 's'}';
  }

  Widget _buildSocialIconsRow(UserModel user) {
    final items = <({IconData icon, String? value, VoidCallback onTap})>[
      (
        icon: Icons.camera_alt_outlined,
        value: user.instagram,
        onTap: () => _openSocialUrl(
          handle: user.instagram,
          baseUrl: 'https://instagram.com/',
        ),
      ),
      (
        icon: Icons.business_center_outlined,
        value: user.linkedin,
        onTap: () => _openSocialUrl(
          handle: user.linkedin,
          baseUrl: 'https://www.linkedin.com/in/',
        ),
      ),
      (
        icon: Icons.alternate_email_rounded,
        value: user.twitter,
        onTap: () => _openSocialUrl(
          handle: user.twitter,
          baseUrl: 'https://x.com/',
        ),
      ),
      (
        icon: Icons.code_rounded,
        value: user.github,
        onTap: () => _openSocialUrl(
          handle: user.github,
          baseUrl: 'https://github.com/',
        ),
      ),
      (
        icon: Icons.music_note_rounded,
        value: user.tiktok,
        onTap: () => _openSocialUrl(
          handle: user.tiktok,
          baseUrl: 'https://www.tiktok.com/@',
        ),
      ),
      (
        icon: Icons.language_rounded,
        value: user.website,
        onTap: () => _openWebsite(user.website),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: AppHaptics.wrap(() {
                final hasValue =
                    item.value != null && item.value!.trim().isNotEmpty;
                if (hasValue) {
                  item.onTap();
                } else {
                  _showEditSocialsSheet();
                }
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (item.value != null && item.value!.trim().isNotEmpty)
                      ? BrandColors.primaryOrange.withValues(alpha: 0.2)
                      : BrandColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BrandColors.primaryOrange.withValues(
                      alpha: (item.value != null && item.value!.trim().isNotEmpty)
                          ? 0.5
                          : 0.15,
                    ),
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: (item.value != null && item.value!.trim().isNotEmpty)
                      ? BrandColors.primaryOrange
                      : BrandColors.grayDark,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: BrandColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: AppHaptics.wrap(onTap),
        enableFeedback: false,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: BrandColors.primaryOrange, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandColors.grayMedium,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet() async {
    final user = _currentUser;
    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrandColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BrandColors.grayDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Editar perfil',
                  style: TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _sheetEditRow(
                  ctx,
                  title: 'Nombre',
                  value: user.displayName,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'Nombre',
                      initial: user.displayName ?? '',
                      hint: 'Tu nombre',
                      maxLength: 50,
                      onSave: (v) =>
                          UserManager.updateProfileFields(displayName: v),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'Bio',
                  value: user.bio,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'Bio',
                      initial: user.bio ?? '',
                      hint: 'Una línea sobre ti',
                      maxLength: 120,
                      maxLines: 3,
                      onSave: (v) => UserManager.updateProfileFields(bio: v),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'Empresa',
                  value: user.company,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'Empresa',
                      initial: user.company ?? '',
                      hint: 'Empresa',
                      maxLength: 60,
                      onSave: (v) =>
                          UserManager.updateProfileFields(company: v),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'Rol',
                  value: user.role,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'Rol',
                      initial: user.role ?? '',
                      hint: 'Founder, Developer...',
                      maxLength: 60,
                      onSave: (v) => UserManager.updateProfileFields(role: v),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditSocialsSheet() async {
    final user = _currentUser;
    if (user == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrandColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BrandColors.grayDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Redes sociales',
                  style: TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _sheetEditRow(
                  ctx,
                  title: 'Instagram',
                  value: user.instagram,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'Instagram',
                      initial: user.instagram ?? '',
                      hint: '@usuario',
                      onSave: (v) => UserManager.updateProfileFields(
                        instagram: _normalizeHandle(v),
                      ),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'LinkedIn',
                  value: user.linkedin,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'LinkedIn',
                      initial: user.linkedin ?? '',
                      hint: 'usuario',
                      onSave: (v) => UserManager.updateProfileFields(
                        linkedin: _normalizeHandle(v, stripAt: false),
                      ),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'X',
                  value: user.twitter,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'X',
                      initial: user.twitter ?? '',
                      hint: '@usuario',
                      onSave: (v) => UserManager.updateProfileFields(
                        twitter: _normalizeHandle(v),
                      ),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'GitHub',
                  value: user.github,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'GitHub',
                      initial: user.github ?? '',
                      hint: 'usuario',
                      onSave: (v) => UserManager.updateProfileFields(
                        github: _normalizeHandle(v, stripAt: false),
                      ),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'TikTok',
                  value: user.tiktok,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'TikTok',
                      initial: user.tiktok ?? '',
                      hint: '@usuario',
                      onSave: (v) => UserManager.updateProfileFields(
                        tiktok: _normalizeHandle(v),
                      ),
                    );
                  },
                ),
                _sheetEditRow(
                  ctx,
                  title: 'Sitio web',
                  value: user.website,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _editTextField(
                      title: 'Sitio web',
                      initial: user.website ?? '',
                      hint: 'https://...',
                      onSave: (v) => UserManager.updateProfileFields(
                        website: _normalizeWebsite(v),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetEditRow(
    BuildContext ctx, {
    required String title,
    required String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: BrandColors.primaryWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        hasValue ? value.trim() : 'Sin configurar',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasValue ? BrandColors.grayMedium : BrandColors.grayDark,
        ),
      ),
      trailing: Icon(
        hasValue ? Icons.edit_rounded : Icons.add_rounded,
        color: BrandColors.primaryOrange,
        size: 20,
      ),
      onTap: AppHaptics.wrap(onTap),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    String? value,
    String placeholder = 'Sin completar',
    bool isEditable = true,
    int maxLines = 1,
    VoidCallback? onEdit,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BrandColors.primaryOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: BrandColors.grayMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value.trim() : placeholder,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasValue
                        ? BrandColors.primaryWhite
                        : BrandColors.grayDark,
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable && onEdit != null)
            IconButton(
              onPressed: AppHaptics.wrap(onEdit),
              icon: const Icon(
                Icons.edit_rounded,
                color: BrandColors.primaryOrange,
                size: 20,
              ),
              tooltip: 'Editar',
            ),
        ],
      ),
    );
  }

  Widget _buildSocialCard({
    required String title,
    required IconData icon,
    required String placeholder,
    String? value,
    required VoidCallback onEdit,
    required VoidCallback onOpen,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BrandColors.primaryOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: hasValue ? AppHaptics.wrap(onOpen) : AppHaptics.wrap(onEdit),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value.trim() : placeholder,
                    style: TextStyle(
                      color: hasValue
                          ? BrandColors.primaryOrange
                          : BrandColors.grayDark,
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      decoration:
                          hasValue ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: BrandColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: AppHaptics.wrap(onEdit),
            icon: Icon(
              hasValue ? Icons.edit_rounded : Icons.add_rounded,
              color: BrandColors.primaryOrange,
              size: 20,
            ),
            tooltip: hasValue ? 'Editar' : 'Agregar',
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: BrandColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: AppHaptics.wrap(onTap),
        enableFeedback: false,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: BrandColors.primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: BrandColors.grayMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: BrandColors.primaryOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: BrandColors.primaryWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.primaryOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pronto',
                        style: TextStyle(
                          color: BrandColors.primaryOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    );
  }

  Future<void> _editTextField({
    required String title,
    required String initial,
    required String hint,
    required Future<UserModel> Function(String value) onSave,
    int maxLength = 80,
    int maxLines = 1,
  }) async {
    _fieldController.text = initial;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrandColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BrandColors.grayDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Editar $title',
                style: const TextStyle(
                  color: BrandColors.primaryWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _fieldController,
                autofocus: true,
                maxLength: maxLength,
                maxLines: maxLines,
                style: const TextStyle(color: BrandColors.primaryWhite),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: BrandColors.grayMedium),
                  filled: true,
                  fillColor: BrandColors.primaryBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: BrandColors.primaryOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: BrandColors.primaryOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: BrandColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: BrandColors.grayMedium),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(_fieldController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primaryOrange,
                        foregroundColor: BrandColors.primaryWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted) return;
    if (result == initial.trim()) return;

    setState(() => _isSavingField = true);
    try {
      final updated = await onSave(result);
      if (!mounted) return;
      setState(() {
        _currentUser = updated;
        _isSavingField = false;
      });
      _showSuccessSnackBar('$title actualizado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingField = false);
      _showErrorSnackBar('No se pudo guardar: $e');
    }
  }

  String _normalizeHandle(String raw, {bool stripAt = true}) {
    var v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) {
      final uri = Uri.tryParse(v);
      if (uri != null) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          v = segments.last;
        }
      }
    }
    if (stripAt && v.startsWith('@')) v = v.substring(1);
    return v;
  }

  String _normalizeWebsite(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://$v';
  }

  Future<void> _openSocialUrl({
    required String? handle,
    required String baseUrl,
  }) async {
    if (handle == null || handle.trim().isEmpty) return;
    final h = handle.trim();
    final url = h.startsWith('http') ? h : '$baseUrl$h';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWebsite(String? website) async {
    if (website == null || website.trim().isEmpty) return;
    final uri = Uri.tryParse(_normalizeWebsite(website));
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAdminWeb() async {
    final uri = Uri.parse('https://devlokos.com/admin');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmailApp() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'info@devlokos.com',
      query: 'subject=Colaboración DevLokos',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showImagePickerOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: BrandColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Foto de perfil',
                  style: TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: BrandColors.primaryOrange),
                  title: const Text('Galería',
                      style: TextStyle(color: BrandColors.primaryWhite)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: BrandColors.primaryOrange),
                  title: const Text('Cámara',
                      style: TextStyle(color: BrandColors.primaryWhite)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      if (!ImageStorageService.validateImage(file)) {
        _showErrorSnackBar('Imagen no válida');
        return;
      }
      final compressed = await ImageStorageService.compressImage(file);
      await _uploadImage(compressed);
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _uploadImage(File file) async {
    if (!mounted) return;
    setState(() => _isUploadingImage = true);
    try {
      await ImageStorageService.uploadProfileImage(file);
      final refreshed = await UserManager.getUser();
      if (!mounted) return;
      setState(() {
        _currentUser = refreshed;
        _isUploadingImage = false;
      });
      _showSuccessSnackBar('Foto actualizada');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar('Error al subir foto: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
