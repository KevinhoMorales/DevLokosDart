import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/course.dart';
import '../../repository/course_admin_repository.dart';
import '../../services/course_image_service.dart';

class CourseFormScreen extends StatefulWidget {
  final Course? course; // Si es null, es crear. Si tiene valor, es editar

  const CourseFormScreen({
    super.key,
    this.course,
  });

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CourseAdminRepository();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _professorController = TextEditingController();
  final _durationController = TextEditingController();

  // Estado
  File? _coverImage;
  String? _coverImageUrl;
  bool _isFree = true;
  bool _isPublished = false;
  String _selectedDifficulty = 'Beginner';
  List<String> _selectedLearningPaths = [];
  bool _isLoading = false;

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _learningPaths = ['Mobile', 'Backend', 'DevOps'];

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _loadCourseData();
    } else {
      // Si no hay curso pero hay un ID en la ruta, cargarlo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCourseFromRoute();
      });
    }
  }

  Future<void> _loadCourseFromRoute() async {
    // Esta función se puede usar si se pasa el ID por la ruta
    // Por ahora, el curso se pasa directamente al widget
  }

  void _loadCourseData() {
    final course = widget.course!;
    _titleController.text = course.title;
    _descriptionController.text = course.description;
    _professorController.text = course.professor ?? '';
    _linkController.text = course.link ?? '';
    _durationController.text = course.duration.toString();
    _coverImageUrl = course.thumbnailUrl;
    _isFree = !course.isPaid;
    _isPublished = course.isPublished;
    _selectedDifficulty = course.difficulty;
    _selectedLearningPaths = List.from(course.learningPaths);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _professorController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.course == null ? 'Nuevo Curso' : 'Editar Curso',
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Imagen de portada
                _buildCoverImageSection(),
                const SizedBox(height: 24),

                // Título
                _buildTextField(
                  controller: _titleController,
                  label: 'Título del Curso',
                  hint: 'Ej: Introducción a Flutter',
                  icon: Icons.title,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Descripción',
                  hint: 'Describe el contenido del curso',
                  icon: Icons.description,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Enlace
                _buildTextField(
                  controller: _linkController,
                  label: 'Enlace del Curso',
                  hint: 'https://...',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // Profesor
                _buildTextField(
                  controller: _professorController,
                  label: 'Profesor',
                  hint: 'Nombre del instructor',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Duración
                _buildTextField(
                  controller: _durationController,
                  label: 'Duración (minutos)',
                  hint: '120',
                  icon: Icons.access_time,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final duration = int.tryParse(value);
                      if (duration == null || duration <= 0) {
                        return 'Ingresa una duración válida';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Dificultad
                _buildDropdown(
                  label: 'Dificultad',
                  value: _selectedDifficulty,
                  items: _difficulties,
                  onChanged: (value) {
                    setState(() {
                      _selectedDifficulty = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Rutas de aprendizaje
                _buildLearningPathsSection(),
                const SizedBox(height: 24),

                // Es gratuito
                _buildSwitch(
                  label: 'Curso Gratuito',
                  value: _isFree,
                  onChanged: (value) {
                    setState(() {
                      _isFree = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Publicado
                _buildSwitch(
                  label: 'Publicar Curso',
                  value: _isPublished,
                  onChanged: (value) {
                    setState(() {
                      _isPublished = value;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Botón guardar
                _buildSaveButton(),
                const SizedBox(height: 16),

                // Botón eliminar (solo si es edición)
                if (widget.course != null) _buildDeleteButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen de Portada',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: BrandColors.primaryWhite,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: BrandColors.blackLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BrandColors.primaryOrange.withOpacity(0.3),
              ),
            ),
            child: _coverImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _coverImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : _coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: BrandColors.grayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Toca para agregar imagen',
            style: TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BrandColors.grayMedium,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: BrandColors.primaryWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: BrandColors.grayDark),
            prefixIcon: Icon(icon, color: BrandColors.primaryOrange),
            filled: true,
            fillColor: BrandColors.blackLight,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BrandColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BrandColors.grayMedium,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: BrandColors.blackLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BrandColors.primaryOrange.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(color: BrandColors.primaryWhite),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            dropdownColor: BrandColors.blackLight,
            style: const TextStyle(color: BrandColors.primaryWhite),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningPathsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rutas de Aprendizaje',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BrandColors.grayMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _learningPaths.map((path) {
            final isSelected = _selectedLearningPaths.contains(path);
            return FilterChip(
              label: Text(path),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLearningPaths.add(path);
                  } else {
                    _selectedLearningPaths.remove(path);
                  }
                });
              },
              backgroundColor: BrandColors.blackLight,
              selectedColor: BrandColors.primaryOrange.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? BrandColors.primaryOrange
                    : BrandColors.primaryWhite,
              ),
              side: BorderSide(
                color: isSelected
                    ? BrandColors.primaryOrange
                    : BrandColors.grayMedium,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.blackLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: BrandColors.primaryWhite,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: BrandColors.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primaryOrange,
          foregroundColor: BrandColors.primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  BrandColors.primaryWhite,
                ),
              )
            : Text(
                widget.course == null ? 'CREAR CURSO' : 'GUARDAR CAMBIOS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _deleteCourse,
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.error,
          side: const BorderSide(color: BrandColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'ELIMINAR CURSO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _coverImage = File(image.path);
          _coverImageUrl = null; // Limpiar URL si hay imagen local
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLearningPaths.isEmpty) {
      _showError('Selecciona al menos una ruta de aprendizaje');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      if (widget.course == null) {
        // Crear nuevo curso - primero crear con ID temporal para subir imagen
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Subir imagen si hay una nueva (usando tempId)
        String? finalCoverImageUrl = _coverImageUrl;
        if (_coverImage != null && finalCoverImageUrl == null) {
          finalCoverImageUrl = await CourseImageService.uploadCourseCoverImage(
            _coverImage!,
            tempId,
          );
        }

        final course = Course(
          id: '', // Se generará en Firestore
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          learningObjectives: [], // Se puede agregar después
          difficulty: _selectedDifficulty,
          duration: int.tryParse(_durationController.text) ?? 0,
          thumbnailUrl: finalCoverImageUrl,
          learningPaths: _selectedLearningPaths,
          modules: [], // Se puede agregar después
          isPublished: _isPublished,
          isPaid: !_isFree,
          createdAt: now,
          updatedAt: now,
          publishedAt: _isPublished ? now : null,
          professor: _professorController.text.trim().isEmpty 
              ? null 
              : _professorController.text.trim(),
          link: _linkController.text.trim().isEmpty 
              ? null 
              : _linkController.text.trim(),
        );

        final courseId = await _repository.createCourse(course);
        _showSuccess('Curso creado exitosamente');
        
        // Si se subió imagen con tempId, actualizar con el ID real
        if (_coverImage != null && courseId != tempId) {
          // Opcional: renombrar/actualizar la imagen con el ID real
          // Por ahora, la imagen ya está subida y funciona
        }
      } else {
        // Actualizar curso existente
        String? finalCoverImageUrl = _coverImageUrl;
        
        // Subir nueva imagen si hay una
        if (_coverImage != null) {
          finalCoverImageUrl = await CourseImageService.uploadCourseCoverImage(
            _coverImage!,
            widget.course!.id,
          );
        }

        final course = Course(
          id: widget.course!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          learningObjectives: widget.course!.learningObjectives,
          difficulty: _selectedDifficulty,
          duration: int.tryParse(_durationController.text) ?? 0,
          thumbnailUrl: finalCoverImageUrl,
          learningPaths: _selectedLearningPaths,
          modules: widget.course!.modules,
          finalProjectId: widget.course!.finalProjectId,
          isPublished: _isPublished,
          isPaid: !_isFree,
          createdAt: widget.course!.createdAt,
          updatedAt: now,
          publishedAt: _isPublished && widget.course!.publishedAt == null
              ? now
              : widget.course!.publishedAt,
          enrollmentCount: widget.course!.enrollmentCount,
          professor: _professorController.text.trim().isEmpty 
              ? null 
              : _professorController.text.trim(),
          link: _linkController.text.trim().isEmpty 
              ? null 
              : _linkController.text.trim(),
        );

        await _repository.updateCourse(widget.course!.id, course);
        _showSuccess('Curso actualizado exitosamente');
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showError('Error al guardar curso: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCourse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Eliminar Curso',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este curso? Esta acción no se puede deshacer.',
          style: TextStyle(color: BrandColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: BrandColors.grayMedium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: BrandColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.deleteCourse(widget.course!.id);
      _showSuccess('Curso eliminado exitosamente');
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showError('Error al eliminar curso: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
