import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../services/push_notification_service.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/gradient_button.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> bullets;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.bullets = const [],
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  late final AnimationController _iconPulseController;
  late final Animation<double> _iconPulse;

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      title: 'Bienvenido a DevLokos',
      subtitle:
          'Tu espacio para aprender, crear y crecer en tecnología. Todo el contenido de la comunidad, en un solo lugar.',
    ),
    _OnboardingPage(
      icon: Icons.radio_rounded,
      title: 'Podcast y Tutoriales',
      subtitle: 'Contenido fresco para seguir aprendiendo a tu ritmo.',
      bullets: [
        'Podcast con episodios por temporada',
        'Tutoriales prácticos para desarrolladores',
      ],
    ),
    _OnboardingPage(
      icon: Icons.school_rounded,
      title: 'Academia, Empresarial y Eventos',
      subtitle: 'Da el siguiente paso en tu carrera y en tu negocio.',
      bullets: [
        'Cursos de la Academia DevLokos',
        'Servicios y portafolio para empresas',
        'Eventos y actividades de la comunidad',
      ],
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: 'Activa las notificaciones',
      subtitle:
          'Te avisamos de nuevos episodios, cursos y eventos. Puedes cambiarlo cuando quieras en Ajustes.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _iconPulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconPulseController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool requestNotifications}) async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    try {
      if (requestNotifications) {
        await PushNotificationService().requestNotificationPermission();
      }
      await OnboardingService.markCompleted();
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      await OnboardingService.markCompleted();
      if (!mounted) return;
      context.go('/home');
    }
  }

  void _next() {
    if (_isLastPage) {
      _finish(requestNotifications: true);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  const Spacer(),
                  if (!_isLastPage)
                    TextButton(
                      onPressed: _isFinishing
                          ? null
                          : () => _finish(requestNotifications: false),
                      child: const Text(
                        'Omitir',
                        style: TextStyle(
                          color: BrandColors.grayMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _OnboardingPageView(
                    page: _pages[index],
                    iconPulse: _iconPulse,
                    isActive: index == _currentPage,
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
              child: Column(
                children: [
                  _PageIndicators(
                    count: _pages.length,
                    current: _currentPage,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: _isFinishing ? null : _next,
                    isLoading: _isFinishing && _isLastPage,
                    text: _isLastPage ? 'Activar y empezar' : 'Siguiente',
                    width: double.infinity,
                  ),
                  if (_isLastPage) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isFinishing
                          ? null
                          : () => _finish(requestNotifications: false),
                      child: const Text(
                        'Ahora no',
                        style: TextStyle(
                          color: BrandColors.grayMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final Animation<double> iconPulse;
  final bool isActive;

  const _OnboardingPageView({
    required this.page,
    required this.iconPulse,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: isActive ? iconPulse : const AlwaysStoppedAnimation<double>(1),
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BrandColors.primaryOrange.withValues(alpha: 0.12),
                border: Border.all(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                page.icon,
                size: 52,
                color: BrandColors.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          if (page.bullets.isNotEmpty) ...[
            const SizedBox(height: 28),
            ...page.bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: BrandColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: BrandColors.primaryWhite,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int count;
  final int current;

  const _PageIndicators({
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 28 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? BrandColors.primaryOrange
                : BrandColors.grayDark,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
