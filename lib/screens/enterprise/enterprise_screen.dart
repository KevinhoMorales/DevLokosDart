import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/enterprise/enterprise_bloc_exports.dart';
import '../../repository/enterprise_repository.dart';
import '../../models/enterprise.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';

class EnterpriseScreen extends StatefulWidget {
  const EnterpriseScreen({super.key});

  @override
  State<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends State<EnterpriseScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedProjectType;

  final List<String> _projectTypes = [
    'Custom Software Development',
    'Consulting',
    'Mobile App Development',
    'Web Development',
    'DevOps & Infrastructure',
    'Other',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<EnterpriseBloc>().add(const LoadServices());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: const CustomAppBar(title: ''),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: SafeArea(
          child: BlocListener<EnterpriseBloc, EnterpriseState>(
            listener: (context, state) {
              if (state is ContactFormSubmitted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Formulario enviado exitosamente!'),
                    backgroundColor: BrandColors.success,
                  ),
                );
                _clearForm();
              } else if (state is ContactFormError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: BrandColors.error,
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildServices(),
                  _buildProcess(),
                  _buildPortfolio(),
                  _buildContactForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVICIOS EMPRESARIALES',
            style: TextStyle(
              color: BrandColors.primaryOrange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Desarrollo de software personalizado y servicios de consultoría para empresas',
            style: TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServices() {
    return BlocBuilder<EnterpriseBloc, EnterpriseState>(
      builder: (context, state) {
        if (state is EnterpriseLoaded) {
          final services = state.services;
          if (services.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'NUESTROS SERVICIOS',
                  style: TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _buildServiceCard(service);
                },
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                service.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.title,
                  style: const TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            service.description,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 14,
            ),
          ),
          if (service.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...service.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: BrandColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: BrandColors.primaryWhite,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildProcess() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NUESTRO PROCESO',
            style: TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProcessStep('1', 'Discovery', 'Análisis de requisitos y planificación'),
          _buildProcessStep('2', 'Development', 'Desarrollo ágil y iterativo'),
          _buildProcessStep('3', 'Delivery', 'Entrega y soporte continuo'),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: BrandColors.primaryWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    color: BrandColors.primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: BrandColors.grayMedium,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolio() {
    return BlocBuilder<EnterpriseBloc, EnterpriseState>(
      builder: (context, state) {
        if (state is EnterpriseLoaded) {
          final projects = state.portfolioProjects;
          if (projects.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'PORTFOLIO',
                  style: TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _buildPortfolioCard(project);
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPortfolioCard(PortfolioProject project) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.thumbnailUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: project.thumbnailUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: BrandColors.grayDark,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: BrandColors.primaryOrange,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120,
                  color: BrandColors.grayDark,
                  child: const Icon(
                    Icons.business,
                    color: BrandColors.grayMedium,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: const TextStyle(
                    color: BrandColors.grayMedium,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INICIA UN PROYECTO',
            style: TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Tu nombre',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: BrandColors.cardBackground,
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'tu@email.com',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: BrandColors.cardBackground,
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu email';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Empresa (opcional)',
                    hintText: 'Nombre de tu empresa',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: BrandColors.cardBackground,
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProjectType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de proyecto',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: BrandColors.cardBackground,
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  dropdownColor: BrandColors.cardBackground,
                  items: _projectTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje',
                    hintText: 'Cuéntanos sobre tu proyecto...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: BrandColors.cardBackground,
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un mensaje';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                BlocBuilder<EnterpriseBloc, EnterpriseState>(
                  builder: (context, state) {
                    final isSubmitting = state is ContactFormSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: isSubmitting ? null : _submitForm,
                        text: isSubmitting ? 'ENVIANDO...' : 'ENVIAR',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final submission = ContactSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        message: _messageController.text.trim(),
        projectType: _selectedProjectType,
        submittedAt: DateTime.now(),
      );

      context.read<EnterpriseBloc>().add(SubmitContactForm(submission));
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _companyController.clear();
    _messageController.clear();
    setState(() {
      _selectedProjectType = null;
    });
  }
}
