import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/enterprise/enterprise_bloc_exports.dart';
import '../../models/enterprise.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../utils/responsive.dart';
import '../../utils/service_icons.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/content_skeleton.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/section_header.dart';

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
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedProjectType;
  String _portfolioFilter = 'Todos';

  final ScrollController _portfolioScrollController = ScrollController();
  Timer? _portfolioAutoScrollTimer;
  Timer? _portfolioResumeTimer;
  bool _portfolioUserInteracting = false;

  static const Duration _portfolioTickInterval = Duration(milliseconds: 16);
  static const double _portfolioPixelsPerTick = 0.45;

  static const _portfolioFilters = [
    'Todos',
    'iOS',
    'Android',
    'Web',
    'Flutter',
  ];

  final List<String> _projectTypes = [
    'Desarrollo de software a medida',
    'Consultoría',
    'Desarrollo de aplicaciones móviles',
    'Desarrollo web',
    'DevOps e infraestructura',
    'Otro',
  ];

  /// Contenido de respaldo si Firestore aún no tiene servicios publicados.
  static final List<Service> _fallbackServices = [
    Service(
      id: 'fallback-software',
      title: 'Software a medida',
      description:
          'Productos y plataformas pensadas para tu operación, no plantillas genéricas.',
      icon: 'code',
      features: const [
        'Descubrimiento y arquitectura',
        'Desarrollo de punta a punta',
        'Entrega continua',
      ],
      order: 0,
    ),
    Service(
      id: 'fallback-mobile',
      title: 'Apps móviles',
      description:
          'iOS y Android con foco en rendimiento, experiencia de usuario y mantenimiento a largo plazo.',
      icon: 'phone_iphone',
      features: const [
        'Flutter con sensación nativa',
        'Integraciones de backend',
        'Publicación en tiendas',
      ],
      order: 1,
    ),
    Service(
      id: 'fallback-consulting',
      title: 'Consultoría técnica',
      description:
          'Acompañamos a tu equipo en decisiones de stack, nube y procesos.',
      icon: 'explore',
      features: const [
        'Auditoría técnica',
        'Hoja de ruta del producto',
        'Mentoría a equipos',
      ],
      order: 2,
    ),
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
    _stopPortfolioAutoScroll();
    _portfolioScrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _schedulePortfolioAutoScroll(int itemCount) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || itemCount <= 1) {
        _stopPortfolioAutoScroll();
        return;
      }
      if (_portfolioAutoScrollTimer == null ||
          !_portfolioAutoScrollTimer!.isActive) {
        _startPortfolioAutoScroll(itemCount);
      }
    });
  }

  void _startPortfolioAutoScroll(int itemCount) {
    _portfolioAutoScrollTimer?.cancel();
    if (itemCount <= 1) return;
    _portfolioAutoScrollTimer = Timer.periodic(_portfolioTickInterval, (_) {
      _tickPortfolioRail();
    });
  }

  void _stopPortfolioAutoScroll() {
    _portfolioAutoScrollTimer?.cancel();
    _portfolioAutoScrollTimer = null;
    _portfolioResumeTimer?.cancel();
    _portfolioResumeTimer = null;
  }

  void _pausePortfolioAutoScrollTemporarily() {
    _portfolioUserInteracting = true;
    _portfolioResumeTimer?.cancel();
    _portfolioResumeTimer = Timer(const Duration(seconds: 2), () {
      _portfolioUserInteracting = false;
    });
  }

  void _tickPortfolioRail() {
    if (!mounted || _portfolioUserInteracting) return;
    if (!_portfolioScrollController.hasClients) return;
    final position = _portfolioScrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }
    final next = position.pixels + _portfolioPixelsPerTick;
    if (next >= position.maxScrollExtent - 0.5) {
      _portfolioScrollController.jumpTo(0);
    } else {
      _portfolioScrollController.jumpTo(next);
    }
  }

  void _onPortfolioFilterSelected(String filter) {
    setState(() => _portfolioFilter = filter);
    if (_portfolioScrollController.hasClients) {
      _portfolioScrollController.jumpTo(0);
    }
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
          bottom: false,
          child: BlocConsumer<EnterpriseBloc, EnterpriseState>(
            listenWhen: (prev, curr) {
              if (curr is! EnterpriseLoaded) return false;
              final prevLoaded = prev is EnterpriseLoaded ? prev : null;
              final becameSuccess =
                  curr.submitSuccess && !(prevLoaded?.submitSuccess ?? false);
              final becameError = curr.submitError != null &&
                  curr.submitError != prevLoaded?.submitError;
              return becameSuccess || becameError;
            },
            listener: (context, state) {
              if (state is! EnterpriseLoaded) return;
              if (state.submitSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Formulario enviado exitosamente!'),
                    backgroundColor: BrandColors.success,
                  ),
                );
                _clearForm();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              } else if (state.submitError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.submitError!),
                    backgroundColor: BrandColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is EnterpriseLoading || state is EnterpriseInitial) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: ContentSkeleton.card(count: 3),
                );
              }

              if (state is EnterpriseError) {
                return AppErrorState(
                  message: state.message,
                  onRetry: () =>
                      context.read<EnterpriseBloc>().add(const LoadServices()),
                );
              }

              final loaded = state is EnterpriseLoaded
                  ? state
                  : const EnterpriseLoaded(
                      services: [],
                      portfolioProjects: [],
                    );

              final services = loaded.services.isNotEmpty
                  ? loaded.services
                  : _fallbackServices;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactHeader(),
                    _buildProcessSteps(),
                    _buildServices(services),
                    _buildPortfolio(loaded.portfolioProjects),
                    _buildContactCta(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empresarial',
            style: TextStyle(
              color: BrandColors.primaryOrange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Software a medida y consultoría para empresas.',
            style: TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessSteps() {
    const steps = [
      (Icons.search_rounded, '01', 'Descubrimiento'),
      (Icons.palette_outlined, '02', 'Diseño'),
      (Icons.code_rounded, '03', 'Desarrollo'),
      (Icons.rocket_launch_outlined, '04', 'Entrega'),
    ];

    final hPad = Responsive.horizontalPadding(context);
    final crossAxisCount = Responsive.isTablet(context) ? 4 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Nuestro proceso',
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final cols = crossAxisCount;
              final tileW =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: steps.map((step) {
                  return SizedBox(
                    width: tileW,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        cols == 4 ? 14 : 12,
                        cols == 4 ? 14 : 12,
                        cols == 4 ? 14 : 12,
                        cols == 4 ? 14 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: BrandColors.primaryOrange
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                step.$1,
                                color: BrandColors.primaryOrange,
                                size: cols == 4 ? 20 : 18,
                              ),
                              const Spacer(),
                              Text(
                                step.$2,
                                style: TextStyle(
                                  color: BrandColors.primaryOrange
                                      .withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.$3,
                            style: TextStyle(
                              color: BrandColors.primaryWhite,
                              fontSize: cols == 4 ? 14 : 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServices(List<Service> services) {
    if (services.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Servicios',
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
        ),
        ...services.map(
          (service) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _buildServiceCard(service),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              serviceIconData(service.icon),
              color: BrandColors.primaryOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: const TextStyle(
                    color: BrandColors.primaryWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.description,
                  style: const TextStyle(
                    color: BrandColors.grayMedium,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (service.features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: service.features.take(3).map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BrandColors.primaryBlack.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BrandColors.primaryOrange
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: BrandColors.grayLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolio(List<PortfolioProject> projects) {
    if (projects.isEmpty) return const SizedBox.shrink();

    final filtered = _portfolioFilter == 'Todos'
        ? projects
        : projects
            .where(
              (p) =>
                  p.category.toLowerCase() == _portfolioFilter.toLowerCase(),
            )
            .toList();

    final hPad = Responsive.horizontalPadding(context);
    final tablet = Responsive.isTablet(context);
    final wide = Responsive.isWide(context);
    final cardWidth = wide ? 260.0 : (tablet ? 240.0 : 212.0);
    final railHeight = wide ? 300.0 : (tablet ? 286.0 : 268.0);
    const gap = 12.0;

    if (filtered.length > 1) {
      _schedulePortfolioAutoScroll(filtered.length);
    } else {
      _stopPortfolioAutoScroll();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Portafolio',
          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 4),
          count: projects.length,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
          child: const Text(
            'Proyectos reales — desliza o déjalos pasar solos.',
            style: TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
            itemCount: _portfolioFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _portfolioFilters[index];
              final active = filter == _portfolioFilter;
              return FilterChip(
                label: Text(filter),
                selected: active,
                showCheckmark: false,
                onSelected: (_) => _onPortfolioFilterSelected(filter),
                selectedColor: BrandColors.primaryOrange,
                backgroundColor: BrandColors.cardBackground,
                labelStyle: TextStyle(
                  color: active
                      ? BrandColors.primaryWhite
                      : BrandColors.grayMedium,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: active
                      ? BrandColors.primaryOrange
                      : BrandColors.primaryOrange.withValues(alpha: 0.25),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
            child: const Text(
              'No hay proyectos en esta categoría.',
              style: TextStyle(color: BrandColors.grayMedium, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: railHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _pausePortfolioAutoScrollTemporarily();
                }
                return false;
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView.builder(
                  controller: _portfolioScrollController,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardWidth,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < filtered.length - 1 ? gap : 0,
                        ),
                        child: _buildPortfolioCard(filtered[index]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openPortfolioUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.cardBackground,
        title: const Text(
          'Abrir proyecto',
          style: TextStyle(color: BrandColors.primaryWhite),
        ),
        content: const Text(
          '¿Quieres abrir este proyecto en otra app?',
          style: TextStyle(color: BrandColors.grayMedium),
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
    if (confirmed != true) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildPortfolioCard(PortfolioProject project) {
    final card = Container(
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.primaryOrange.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 132,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (project.thumbnailUrl != null &&
                    project.thumbnailUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: project.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: BrandColors.grayDark),
                    errorWidget: (context, url, error) => Container(
                      color: BrandColors.blackLight,
                      child: const Icon(
                        Icons.folder_open_rounded,
                        color: BrandColors.primaryOrange,
                      ),
                    ),
                  )
                else
                  Container(
                    color: BrandColors.blackLight,
                    child: const Center(
                      child: Icon(
                        Icons.folder_open_rounded,
                        color: BrandColors.primaryOrange,
                        size: 36,
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
                if (project.category.isNotEmpty)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.primaryWhite,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        project.category,
                        style: const TextStyle(
                          color: BrandColors.primaryBlack,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      color: BrandColors.primaryWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      project.description,
                      style: const TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ver proyecto',
                    style: TextStyle(
                      color: BrandColors.primaryOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final url = project.projectUrl;
    if (url == null || url.isEmpty) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: AppHaptics.wrap(() => _openPortfolioUrl(url)),
        child: card,
      ),
    );
  }

  Widget _buildContactCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: BrandColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: BrandColors.primaryOrange.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Listo para construir?',
              style: TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuéntanos tu proyecto y te respondemos en menos de 24 h.',
              style: TextStyle(
                color: BrandColors.grayMedium,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: () {
                  AppHaptics.light();
                  _openContactSheet();
                },
                text: 'Inicia un proyecto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openContactSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrandColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setSheetState) {
                  return _buildContactFormSheet(
                    scrollController,
                    setSheetState,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContactFormSheet(
    ScrollController scrollController,
    StateSetter setSheetState,
  ) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: BrandColors.grayMedium.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicia un proyecto',
                      style: TextStyle(
                        color: BrandColors.primaryWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Te respondemos en menos de 24 h',
                      style: TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: BrandColors.grayMedium),
              ),
            ],
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    label: 'Nombre completo',
                    hint: 'Tu nombre y apellido',
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration(
                    label: 'Correo electrónico',
                    hint: 'tu@email.com',
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration(
                    label: 'Teléfono (opcional)',
                    hint: '+52 55 1234 5678',
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _companyController,
                  decoration: _inputDecoration(
                    label: 'Empresa (opcional)',
                    hint: 'Nombre de tu empresa',
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedProjectType,
                  hint: const Text(
                    'Selecciona una opción',
                    style: TextStyle(color: BrandColors.grayMedium),
                  ),
                  decoration: _inputDecoration(
                    label: 'Tipo de proyecto',
                    hint: 'Selecciona una opción',
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
                    setSheetState(() {
                      _selectedProjectType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  decoration: _inputDecoration(
                    label: 'Mensaje',
                    hint:
                        'Cuéntanos sobre tu proyecto, necesidades o preguntas...',
                  ),
                  style: const TextStyle(color: BrandColors.primaryWhite),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor escribe tu mensaje';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                BlocBuilder<EnterpriseBloc, EnterpriseState>(
                  builder: (context, state) {
                    final isSubmitting =
                        state is EnterpriseLoaded && state.isSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: isSubmitting ? null : _submitForm,
                        isLoading: isSubmitting,
                        text: isSubmitting ? 'Enviando...' : 'Enviar mensaje',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: BrandColors.grayMedium),
      hintStyle: const TextStyle(color: BrandColors.grayMedium),
      filled: true,
      fillColor: BrandColors.primaryBlack.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: BrandColors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: BrandColors.primaryOrange,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      AppHaptics.light();
      final submission = ContactSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
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
    _phoneController.clear();
    _companyController.clear();
    _messageController.clear();
    setState(() {
      _selectedProjectType = null;
    });
  }
}
