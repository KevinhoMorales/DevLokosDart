import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../models/event.dart';
import '../../repository/event_repository.dart';
import '../../services/event_image_service.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = EventRepository();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _registrationUrlController = TextEditingController();

  File? _coverImage;
  String? _coverImageUrl;
  DateTime? _eventDate;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _loadEventData();
    }
  }

  void _loadEventData() {
    final e = widget.event!;
    _titleController.text = e.title;
    _descriptionController.text = e.description;
    _locationController.text = e.location;
    _cityController.text = e.city;
    _registrationUrlController.text = e.registrationUrl ?? '';
    _coverImageUrl = e.imageUrl;
    _eventDate = e.eventDate;
    _isActive = e.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _registrationUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.event == null ? 'Nuevo Evento' : 'Editar Evento',
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(color: BrandColors.primaryBlack),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _titleController,
                  label: 'Nombre del evento',
                  hint: 'Ej: Café Cursor, Build with AI',
                  icon: Icons.event,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Descripción',
                  hint: 'Describe el evento',
                  icon: Icons.description,
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                _buildDateSection(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Lugar',
                  hint: 'Dirección o nombre del lugar',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cityController,
                  label: 'Ciudad',
                  hint: 'Ej: Ciudad de México',
                  icon: Icons.place,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _registrationUrlController,
                  label: 'URL de registro',
                  hint: 'https://...',
                  icon: Icons.link,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),
                _buildSwitch(
                  label: 'Evento activo (visible para usuarios)',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 32),
                _buildSaveButton(),
                if (widget.event != null) ...[
                  const SizedBox(height: 16),
                  _buildDeleteButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen del evento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BrandColors.grayMedium,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 180,
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
                    child: Image.file(_coverImage!, fit: BoxFit.cover),
                  )
                : _coverImageUrl != null && _coverImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
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
          Icon(Icons.add_photo_alternate,
              size: 48, color: BrandColors.grayMedium),
          const SizedBox(height: 8),
          Text(
            'Toca para agregar imagen',
            style: TextStyle(color: BrandColors.grayMedium, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha y hora del evento',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: BrandColors.grayMedium,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrandColors.blackLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: BrandColors.primaryOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: BrandColors.primaryOrange),
                const SizedBox(width: 12),
                Text(
                  _eventDate != null
                      ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year} '
                          '${_eventDate!.hour.toString().padLeft(2, '0')}:'
                          '${_eventDate!.minute.toString().padLeft(2, '0')}'
                      : 'Seleccionar fecha y hora',
                  style: TextStyle(
                    color: _eventDate != null
                        ? BrandColors.primaryWhite
                        : BrandColors.grayDark,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BrandColors.primaryOrange,
              onPrimary: BrandColors.primaryWhite,
              surface: BrandColors.blackLight,
              onSurface: BrandColors.primaryWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _eventDate != null
            ? TimeOfDay.fromDateTime(_eventDate!)
            : const TimeOfDay(hour: 18, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: BrandColors.primaryOrange,
                onPrimary: BrandColors.primaryWhite,
                surface: BrandColors.blackLight,
                onSurface: BrandColors.primaryWhite,
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null && mounted) {
        setState(() {
          _eventDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
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
              borderSide: const BorderSide(color: BrandColors.primaryOrange),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BrandColors.error),
            ),
          ),
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: BrandColors.primaryWhite,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: BrandColors.primaryOrange.withOpacity(0.5),
            activeThumbColor: BrandColors.primaryOrange,
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
        onPressed: _isLoading ? null : _saveEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primaryOrange,
          foregroundColor: BrandColors.primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(BrandColors.primaryWhite),
                ),
              )
            : Text(
                widget.event == null ? 'CREAR EVENTO' : 'GUARDAR CAMBIOS',
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
        onPressed: _isLoading ? null : _deleteEvent,
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.error,
          side: const BorderSide(color: BrandColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'ELIMINAR EVENTO',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() {
          _coverImage = File(xFile.path);
          _coverImageUrl = null;
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _coverImageUrl;

      if (_coverImage != null) {
        final eventId = widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await EventImageService.uploadEventImage(_coverImage!, eventId);
      }

      final now = DateTime.now();
      final event = Event(
        id: widget.event?.id ?? '',
        imageUrl: imageUrl ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _eventDate,
        location: _locationController.text.trim(),
        city: _cityController.text.trim(),
        registrationUrl: _registrationUrlController.text.trim().isEmpty
            ? null
            : _registrationUrlController.text.trim(),
        createdAt: widget.event?.createdAt ?? now,
        isActive: _isActive,
      );

      if (widget.event == null) {
        await _repository.createEvent(event);
        _showSuccess('Evento creado exitosamente');
      } else {
        await _repository.updateEvent(widget.event!.id, event);
        _showSuccess('Evento actualizado exitosamente');
      }

      if (mounted) context.pop();
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.blackLight,
        title: const Text(
          'Eliminar evento',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          'El evento se eliminará y dejará de mostrarse a los usuarios. ¿Continuar?',
          style: TextStyle(color: BrandColors.grayMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: BrandColors.grayMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: BrandColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _repository.deleteEvent(widget.event!.id);
      _showSuccess('Evento eliminado');
      if (mounted) context.pop();
    } catch (e) {
      _showError('Error al eliminar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: BrandColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: BrandColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
