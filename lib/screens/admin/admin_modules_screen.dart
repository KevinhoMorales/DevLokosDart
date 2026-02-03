import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import 'course_form_screen.dart';

class AdminModulesScreen extends StatelessWidget {
  const AdminModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Administración',
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Header
              Text(
                'Gestiona el contenido de la plataforma',
                style: TextStyle(
                  fontSize: 16,
                  color: BrandColors.grayMedium,
                ),
              ),
              const SizedBox(height: 32),

              // Módulo 1: Gestión de Cursos
              _buildModuleCard(
                context: context,
                icon: Icons.school,
                title: 'Gestión de Cursos',
                description: 'Crear, editar y eliminar cursos',
                onTap: () {
                  context.push('/admin/courses').then((_) {
                    // Recargar si es necesario
                  });
                },
              ),
              const SizedBox(height: 16),

              // Más módulos pueden agregarse aquí en el futuro
              // _buildModuleCard(...),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: BrandColors.blackShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: BrandColors.primaryOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: BrandColors.grayMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: BrandColors.grayMedium,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
