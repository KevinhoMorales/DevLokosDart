import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/auth/auth_bloc_exports.dart';
import '../../services/admin_service.dart';
import '../../services/image_storage_service.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../utils/login_helper.dart';
import '../../utils/user_manager.dart';
import '../../widgets/custom_app_bar.dart' show AppBarIconAction, CustomAppBar;

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
  bool _isAdmin = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    var user = await UserManager.getUser();
    if (user != null) {
      final synced = await UserManager.syncUserOnAppStart();
      if (synced != null) user = synced;
    }
    if (!mounted) return;

    // Sin sesión: abrir login en bottom sheet y salir (sin pantalla intermedia).
    if (user == null) {
      final authState = context.read<AuthBlocSimple>().state;
      if (authState is! AuthAuthenticated) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await LoginHelper.showLoginBottomSheet(context);
          if (!mounted) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        });
        return;
      }
    }

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

  Future<void> _openEditProfile() async {
    final saved = await context.push<bool>('/profile/edit');
    if (saved == true || saved == null) {
      await _loadUser();
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
            bottom: false,
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
    final user = _currentUser;
    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
        ),
      );
    }
    final bottom = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          if (user.hasBio) ...[
            const SizedBox(height: 16),
            _buildBio(user),
          ],
          const SizedBox(height: 18),
          _buildSocialIconsRow(user),
          const SizedBox(height: 20),
          _buildInfoCard(user),
          const SizedBox(height: 16),
          _buildEditButton(),
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            _buildAdminTile(),
          ],
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BrandColors.grayMedium,
                      fontSize: 12,
                    ),
                children: [
                  const TextSpan(text: 'Hecho con 🧡 en Ecuador · '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: AppHaptics.wrap(_confirmAndOpenEmail),
                      child: const Text(
                        'info@devlokos.com',
                        style: TextStyle(
                          color: BrandColors.primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: BrandColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveDisplayName(UserModel user) {
    final displayName = user.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user.email.trim();
    if (email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return '';
  }

  Widget _buildHeader(UserModel user) {
    final name = _resolveDisplayName(user);
    final hasName = name.isNotEmpty;
    final subtitle = [
      if (user.role != null && user.role!.trim().isNotEmpty) user.role!.trim(),
      if (user.company != null && user.company!.trim().isNotEmpty)
        user.company!.trim(),
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isUploadingImage
              ? null
              : AppHaptics.wrap(_showImagePickerOptions),
          child: Stack(
            children: [
              Container(
                width: 76,
                height: 76,
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
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BrandColors.primaryOrange,
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 34,
                            color: BrandColors.primaryOrange,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: BrandColors.primaryOrange,
                      ),
              ),
              if (_isUploadingImage)
                Container(
                  width: 76,
                  height: 76,
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
                    width: 24,
                    height: 24,
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
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: AppHaptics.wrap(_openEditProfile),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? name : 'Agregar nombre',
                  style: TextStyle(
                    color: hasName
                        ? BrandColors.primaryWhite
                        : BrandColors.grayMedium,
                    fontSize: hasName ? 22 : 16,
                    fontWeight: hasName ? FontWeight.bold : FontWeight.w600,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: BrandColors.primaryOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Completa rol y empresa',
                    style: TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (user.email.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    user.email.trim(),
                    style: const TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBio(UserModel user) {
    return Text(
      user.bio!.trim(),
      style: const TextStyle(
        color: BrandColors.primaryWhite,
        fontSize: 14,
        height: 1.45,
      ),
    );
  }

  /// Mes abreviado en español (evita "Aug" del locale del dispositivo).
  String _formatMemberSince(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildInfoCard(UserModel user) {
    final rows = <({String label, String value, IconData icon})>[
      if (user.role != null && user.role!.trim().isNotEmpty)
        (label: 'Rol', value: user.role!.trim(), icon: Icons.work_outline_rounded),
      if (user.company != null && user.company!.trim().isNotEmpty)
        (
          label: 'Empresa',
          value: user.company!.trim(),
          icon: Icons.apartment_rounded
        ),
      if (user.email.trim().isNotEmpty)
        (
          label: 'Correo',
          value: user.email.trim(),
          icon: Icons.mail_outline_rounded
        ),
      if (user.createdAt != null)
        (
          label: 'Miembro desde',
          value: _formatMemberSince(user.createdAt!),
          icon: Icons.calendar_today_outlined
        ),
    ];

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: i < rows.length - 1
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: BrandColors.primaryOrange.withValues(alpha: 0.10),
                        ),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: BrandColors.primaryOrange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      rows[i].icon,
                      color: BrandColors.primaryOrange,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].label,
                          style: const TextStyle(
                            color: BrandColors.grayMedium,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rows[i].value,
                          style: const TextStyle(
                            color: BrandColors.primaryWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: AppHaptics.wrap(_openEditProfile),
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.primaryOrange,
          side: BorderSide(
            color: BrandColors.primaryOrange.withValues(alpha: 0.55),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildAdminTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: AppHaptics.wrap(_openAdminWeb),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: BrandColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.16),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administración web',
                style: TextStyle(
                  color: BrandColors.primaryWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Panel DevLokos',
                style: TextStyle(
                  color: BrandColors.grayMedium,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIconsRow(UserModel user) {
    final items = <({String label, VoidCallback onTap})>[
      if (user.instagram != null && user.instagram!.trim().isNotEmpty)
        (
          label: 'Instagram',
          onTap: () => _openSocialUrl(
            label: 'Instagram',
            handle: user.instagram,
            baseUrl: 'https://instagram.com/',
          ),
        ),
      if (user.linkedin != null && user.linkedin!.trim().isNotEmpty)
        (
          label: 'LinkedIn',
          onTap: () => _openSocialUrl(
            label: 'LinkedIn',
            handle: user.linkedin,
            baseUrl: 'https://www.linkedin.com/in/',
          ),
        ),
      if (user.twitter != null && user.twitter!.trim().isNotEmpty)
        (
          label: 'X',
          onTap: () => _openSocialUrl(
            label: 'X',
            handle: user.twitter,
            baseUrl: 'https://x.com/',
          ),
        ),
      if (user.github != null && user.github!.trim().isNotEmpty)
        (
          label: 'GitHub',
          onTap: () => _openSocialUrl(
            label: 'GitHub',
            handle: user.github,
            baseUrl: 'https://github.com/',
          ),
        ),
      if (user.tiktok != null && user.tiktok!.trim().isNotEmpty)
        (
          label: 'TikTok',
          onTap: () => _openSocialUrl(
            label: 'TikTok',
            handle: user.tiktok,
            baseUrl: 'https://www.tiktok.com/@',
          ),
        ),
      if (user.website != null && user.website!.trim().isNotEmpty)
        (
          label: 'Web',
          onTap: () => _openWebsite(user.website),
        ),
    ];

    if (items.isEmpty) {
      return InkWell(
        onTap: AppHaptics.wrap(_openEditProfile),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: BrandColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.22),
            ),
          ),
          child: const Center(
            child: Text(
              'Agrega tus redes sociales',
              style: TextStyle(
                color: BrandColors.primaryOrange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Redes',
          style: TextStyle(
            color: BrandColors.grayMedium,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              InkWell(
                onTap: AppHaptics.wrap(item.onTap),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrandColors.primaryOrange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: BrandColors.primaryOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _normalizeWebsite(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://$v';
  }

  Future<bool> _confirmOpenExternal({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: Text(
          title,
          style: const TextStyle(color: BrandColors.primaryWhite),
        ),
        content: Text(
          message,
          style: const TextStyle(color: BrandColors.grayMedium),
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
              'Abrir',
              style: TextStyle(
                color: BrandColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _openSocialUrl({
    required String label,
    required String? handle,
    required String baseUrl,
  }) async {
    if (handle == null || handle.trim().isEmpty) return;
    final h = handle.trim();
    final url = h.startsWith('http') ? h : '$baseUrl$h';
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final confirmed = await _confirmOpenExternal(
      title: 'Abrir $label',
      message: '¿Quieres abrir $label en otra app?',
    );
    if (!confirmed || !mounted) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWebsite(String? website) async {
    if (website == null || website.trim().isEmpty) return;
    final uri = Uri.tryParse(_normalizeWebsite(website));
    if (uri == null) return;

    final confirmed = await _confirmOpenExternal(
      title: 'Abrir web',
      message: '¿Quieres abrir este sitio web en el navegador?',
    );
    if (!confirmed || !mounted) return;

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

  Future<void> _confirmAndOpenEmail() async {
    final confirmed = await _confirmOpenExternal(
      title: 'Abrir correo',
      message:
          '¿Quieres abrir tu app de correo para escribir a info@devlokos.com?',
    );
    if (!confirmed || !mounted) return;

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
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: BrandColors.primaryOrange,
                  ),
                  title: const Text(
                    'Galería',
                    style: TextStyle(color: BrandColors.primaryWhite),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: BrandColors.primaryOrange,
                  ),
                  title: const Text(
                    'Cámara',
                    style: TextStyle(color: BrandColors.primaryWhite),
                  ),
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
