import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/settings');
          }
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Acerca de DevLokos',
          showBackButton: true,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: BrandColors.primaryBlack,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(context),
                  const SizedBox(height: 24),
                  _buildStorySection(),
                  const SizedBox(height: 24),
                  _buildLinkSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/devlokos_podcast_host.png',
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            decoration: BoxDecoration(
              color: BrandColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.podcasts,
                size: 64,
                color: BrandColors.primaryOrange,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorySection() {
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
      child: const Text(
        'DevLokos nació una noche con la simple idea de crear un podcast para hablar de desarrollo y tecnología. Sin planearlo mucho, grabamos el primer episodio entre amigos… y desde entonces, el resto es historia.\n\nHoy contamos con más de 150 episodios junto a grandes expertos, una comunidad activa y nuevas iniciativas como DevLokos Tutorials, DevLokos Academy y DevLokos Enterprise, donde ayudamos a las personas a aprender, crear y crecer en el mundo del software.',
        style: TextStyle(
          color: BrandColors.grayMedium,
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildLinkSection(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse('https://linktr.ee/devlokos');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se puede abrir el enlace'),
                backgroundColor: BrandColors.error,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: BrandColors.error,
              ),
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: BrandColors.blackLight.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BrandColors.primaryOrange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link,
              color: BrandColors.primaryOrange,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conéctate con nosotros',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: BrandColors.primaryWhite,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'linktr.ee/devlokos',
                    style: TextStyle(
                      color: BrandColors.primaryOrange,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      decorationColor: BrandColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new,
              color: BrandColors.primaryOrange,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
