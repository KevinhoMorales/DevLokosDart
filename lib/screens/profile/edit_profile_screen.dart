import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../utils/user_manager.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _githubController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _githubController.dispose();
    _tiktokController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserManager.getUser();
    if (!mounted) return;
    if (user == null) {
      context.pop();
      return;
    }
    setState(() {
      _email = user.email;
      _nameController.text = user.displayName ?? '';
      _bioController.text = user.bio ?? '';
      _companyController.text = user.company ?? '';
      _roleController.text = user.role ?? '';
      _instagramController.text = user.instagram ?? '';
      _linkedinController.text = user.linkedin ?? '';
      _twitterController.text = user.twitter ?? '';
      _githubController.text = user.github ?? '';
      _tiktokController.text = user.tiktok ?? '';
      _websiteController.text = user.website ?? '';
      _isLoading = false;
    });
  }

  String _normalizeHandle(String raw, {bool stripAt = true}) {
    var v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) {
      final uri = Uri.tryParse(v);
      if (uri != null) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) v = segments.last;
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

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await UserManager.updateProfileFields(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        company: _companyController.text.trim(),
        role: _roleController.text.trim(),
        instagram: _normalizeHandle(_instagramController.text),
        linkedin: _normalizeHandle(_linkedinController.text, stripAt: false),
        twitter: _normalizeHandle(_twitterController.text),
        github: _normalizeHandle(_githubController.text, stripAt: false),
        tiktok: _normalizeHandle(_tiktokController.text),
        website: _normalizeWebsite(_websiteController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado'),
          backgroundColor: BrandColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $e'),
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
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(
        title: 'Editar perfil',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _isLoading || _isSaving
                ? null
                : AppHaptics.wrap(_save),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BrandColors.primaryOrange,
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: BrandColors.primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  BrandColors.primaryOrange,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_email != null && _email!.isNotEmpty) ...[
                    Text(
                      _email!,
                      style: const TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle('Información'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Nombre',
                    hintText: 'Tu nombre',
                    prefixIcon: Icons.person_outline_rounded,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _bioController,
                    labelText: 'Biografía',
                    hintText: 'Una línea sobre ti',
                    prefixIcon: Icons.notes_rounded,
                    maxLength: 160,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _roleController,
                    labelText: 'Rol',
                    hintText: 'Fundador, Desarrollador…',
                    prefixIcon: Icons.work_outline_rounded,
                    maxLength: 60,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _companyController,
                    labelText: 'Empresa',
                    hintText: 'DevLokos, independiente…',
                    prefixIcon: Icons.apartment_rounded,
                    maxLength: 60,
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Redes sociales'),
                  const SizedBox(height: 4),
                  const Text(
                    'Usa tu usuario o pegá el link completo.',
                    style: TextStyle(
                      color: BrandColors.grayMedium,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _instagramController,
                    labelText: 'Instagram',
                    hintText: '@usuario',
                    prefixIcon: Icons.camera_alt_outlined,
                    maxLength: 80,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _linkedinController,
                    labelText: 'LinkedIn',
                    hintText: 'usuario',
                    prefixIcon: Icons.business_center_outlined,
                    maxLength: 80,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _twitterController,
                    labelText: 'X',
                    hintText: '@usuario',
                    prefixIcon: Icons.alternate_email_rounded,
                    maxLength: 80,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _githubController,
                    labelText: 'GitHub',
                    hintText: 'usuario',
                    prefixIcon: Icons.code_rounded,
                    maxLength: 80,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _tiktokController,
                    labelText: 'TikTok',
                    hintText: '@usuario',
                    prefixIcon: Icons.music_note_rounded,
                    maxLength: 80,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _websiteController,
                    labelText: 'Sitio web',
                    hintText: 'https://…',
                    prefixIcon: Icons.language_rounded,
                    keyboardType: TextInputType.url,
                    maxLength: 120,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: BrandColors.primaryWhite,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
