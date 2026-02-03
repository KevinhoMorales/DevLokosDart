import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/auth/auth_bloc_exports.dart';
import '../../utils/brand_colors.dart';
import '../../utils/user_manager.dart';
import '../../utils/login_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/image_storage_service.dart';
import '../../services/admin_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isUpdatingName = false;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    var user = await UserManager.getUser();
    // Si faltan nombre o foto, intentar sincronizar desde Firestore
    if (user != null && (user.displayName == null || user.displayName!.isEmpty || user.photoURL == null || user.photoURL!.isEmpty)) {
      final synced = await UserManager.syncUserOnAppStart();
      if (synced != null) user = synced;
    }
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      // Verificar si es admin
      _checkAdminStatus();
    }
  }

  Future<void> _checkAdminStatus() async {
    if (_currentUser?.email == null) {
      setState(() {
        _isCheckingAdmin = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      final isAdmin = await AdminService.isEmailAdmin(_currentUser!.email);
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isCheckingAdmin = false;
        });
      }
    } catch (e) {
      print('❌ Error al verificar admin: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
      }
    }
  }

  /// Recarga el usuario y actualiza la UI
  Future<void> _refreshUser() async {
    await _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBlocSimple, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navegar a la pantalla de home cuando se cierre sesión
          context.go('/home');
        } else if (state is AuthAuthenticated) {
          // Refrescar datos del usuario cuando se autentique
          _refreshUser();
        } else if (state is AuthError) {
          // Mostrar error si hay algún problema
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
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: BrandColors.primaryOrange,
                    size: 20,
                  ),
                ),
                tooltip: 'Ajustes',
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
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
              'Por favor, inicia sesión para acceder a tu perfil',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BrandColors.grayMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => LoginHelper.showLoginBottomSheet(context),
              icon: const Icon(Icons.login),
              label: const Text('Iniciar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primaryOrange,
                foregroundColor: BrandColors.primaryWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar Section
          Center(
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _showImagePickerOptions,
              child: Stack(
                children: [
                  Container(
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
                    child: _currentUser?.photoURL != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: CachedNetworkImage(
                              key: ValueKey(_currentUser!.photoURL), // Forzar actualización cuando cambie la URL
                              imageUrl: _currentUser!.photoURL!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              cacheKey: '${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}', // Cache key único
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    BrandColors.primaryOrange,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 60,
                                color: BrandColors.primaryOrange,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: BrandColors.primaryOrange,
                          ),
                  ),
                  if (_isUploadingImage)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            BrandColors.primaryOrange,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: BrandColors.primaryOrange,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: BrandColors.primaryBlack,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: BrandColors.primaryWhite,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // User Information Cards
          _buildInfoCard(
            title: 'Nombre',
            value: _currentUser!.displayName ?? 'No especificado',
            icon: Icons.person_outline,
            isEditable: true,
            onEdit: () => _showEditNameDialog(),
          ),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            title: 'Correo Electrónico',
            value: _currentUser!.email,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 32),

          // Botón de Administración (solo si es admin)
          if (_isAdmin) ...[
            _buildActionButton(
              title: 'Administración',
              icon: Icons.admin_panel_settings,
              onTap: () => context.push('/admin/modules'),
              isDestructive: false,
            ),
            const SizedBox(height: 16),
          ],

          // Footer text and email
          Center(
            child: Column(
              children: [
                Text(
                  'Hecho con 🧡 en Ecuador',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.grayMedium,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openEmailApp,
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Colaboraciones: ',
                          style: TextStyle(
                            color: BrandColors.grayMedium,
                          ),
                        ),
                        TextSpan(
                          text: 'info@devlokos.com',
                          style: TextStyle(
                            color: BrandColors.primaryOrange,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isEditable = false,
    VoidCallback? onEdit,
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
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isEditable && onEdit != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isUpdatingName ? null : onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isUpdatingName
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            BrandColors.primaryOrange,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.edit,
                        color: BrandColors.primaryOrange,
                        size: 20,
                      ),
              ),
            ),
          ],
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
    if (isDestructive) {
      // Botón destructivo con estilo similar a login/register pero rojo
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: BrandColors.primaryWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Botón normal (no destructivo) - mantener el estilo original
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.3),
          width: 1,
        ),
        color: Colors.transparent,
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
                  color: BrandColors.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: BrandColors.primaryWhite,
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

  void _navigateToHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _openSettings() {
    context.push('/settings');
  }

  /// Opens the email app with the collaboration email
  Future<void> _openEmailApp() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@devlokos.com',
      query: 'subject=Colaboraciones DevLokos',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('No se pudo abrir la aplicación de correo');
      }
    } catch (e) {
      print('❌ Error al abrir email: $e');
      _showErrorSnackBar('Error al abrir la aplicación de correo');
    }
  }

  /// Muestra las opciones para seleccionar imagen
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrandColors.blackLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.grayMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cambiar Foto de Perfil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: BrandColors.primaryWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.camera_alt,
                    title: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.photo_library,
                    title: 'Galería',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construye una opción de imagen
  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive 
            ? Colors.red.withOpacity(0.1)
            : BrandColors.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive 
              ? Colors.red.withOpacity(0.3)
              : BrandColors.primaryOrange.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isDestructive ? Colors.red : BrandColors.primaryOrange,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDestructive ? Colors.red : BrandColors.primaryWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Selecciona una imagen desde la cámara o galería
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Validar imagen
        if (!ImageStorageService.validateImage(imageFile)) {
          _showErrorSnackBar('Imagen no válida. Tamaño máximo: 5MB. Formatos: JPG, PNG, WEBP');
          return;
        }

        // Comprimir imagen
        final compressedFile = await ImageStorageService.compressImage(imageFile);
        
        // Subir imagen
        await _uploadImage(compressedFile);
      }
    } catch (e) {
      print('❌ Error al seleccionar imagen: $e');
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  /// Sube la imagen a Firebase Storage
  Future<void> _uploadImage(File imageFile) async {
    if (!mounted) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Subir imagen a Firebase Storage
      final imageUrl = await ImageStorageService.uploadProfileImage(imageFile);
      
      // Actualizar UserManager
      await UserManager.updateUserPhotoURL(imageUrl);
      
      // Actualizar estado local
      if (mounted) {
        setState(() {
          _currentUser = UserModel(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            displayName: _currentUser!.displayName,
            photoURL: imageUrl,
            createdAt: _currentUser!.createdAt,
          );
        });
        
        _showSuccessSnackBar('Foto de perfil actualizada exitosamente');
      }
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      if (mounted) {
        _showErrorSnackBar('Error al subir imagen: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }


  /// Muestra un mensaje de éxito
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Muestra un mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Muestra el diálogo para editar el nombre
  Future<void> _showEditNameDialog() async {
    _nameController.text = _currentUser?.displayName ?? '';
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Editar Nombre',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa tu nuevo nombre:',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: BrandColors.primaryWhite),
              decoration: InputDecoration(
                hintText: 'Nombre completo',
                hintStyle: const TextStyle(color: BrandColors.grayMedium),
                filled: true,
                fillColor: BrandColors.primaryBlack.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: BrandColors.primaryOrange.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: BrandColors.primaryOrange.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: BrandColors.primaryOrange,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: BrandColors.primaryOrange),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _currentUser?.displayName) {
      await _updateUserName(newName);
    }
  }

  /// Actualiza el nombre del usuario
  Future<void> _updateUserName(String newName) async {
    if (!mounted) return;

    setState(() {
      _isUpdatingName = true;
    });

    try {
      // Actualizar UserManager (que sincroniza con Firestore)
      await UserManager.updateUserDisplayName(newName);
      
      // Actualizar estado local
      if (mounted) {
        setState(() {
          _currentUser = UserModel(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            displayName: newName,
            photoURL: _currentUser!.photoURL,
            createdAt: _currentUser!.createdAt,
          );
        });
        
        _showSuccessSnackBar('Nombre actualizado exitosamente');
      }
    } catch (e) {
      print('❌ Error al actualizar nombre: $e');
      if (mounted) {
        _showErrorSnackBar('Error al actualizar nombre: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingName = false;
        });
      }
    }
  }
}

