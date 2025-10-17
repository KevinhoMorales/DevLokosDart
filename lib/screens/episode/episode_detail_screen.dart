import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/episode.dart';
import '../../utils/brand_colors.dart';

class EpisodeDetailScreen extends StatefulWidget {
  final String episodeId;

  const EpisodeDetailScreen({
    super.key,
    required this.episodeId,
  });

  @override
  State<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Episode? _episode;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadEpisode();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _loadEpisode() {
    // Por ahora usamos datos de muestra, después se puede integrar con BLoC
    _episode = Episode(
      id: widget.episodeId,
      title: 'Introducción a Flutter y Dart',
      description: 'En este episodio exploramos los fundamentos de Flutter y Dart, las tecnologías que están revolucionando el desarrollo móvil multiplataforma.',
      thumbnailUrl: 'https://img.youtube.com/vi/1gDhl4jeEuU/maxresdefault.jpg',
      youtubeVideoId: '1gDhl4jeEuU',
      duration: '45:30',
      publishedDate: DateTime(2024, 1, 15),
      category: 'Desarrollo Móvil',
      tags: ['Flutter', 'Dart', 'Mobile', 'Cross-platform'],
      isFeatured: true,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_episode == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: BrandColors.backgroundGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Permitir navegación hacia atrás normalmente
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: BrandColors.backgroundGradient,
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(
          Icons.arrow_back,
          color: BrandColors.primaryWhite,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BrandColors.primaryOrange.withOpacity(0.8),
                BrandColors.primaryOrange.withOpacity(0.4),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.radio,
                  size: 48,
                  color: BrandColors.primaryWhite,
                ),
                const SizedBox(height: 8),
                Text(
                  'DevLokos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BrandColors.primaryWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: BrandColors.orangeShadow,
                gradient: BrandColors.primaryGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_filled,
                      size: 64,
                      color: BrandColors.primaryWhite,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'YouTube Player',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: BrandColors.primaryWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se integrará próximamente',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BrandColors.primaryWhite.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Episode Info
            Text(
              _episode!.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: BrandColors.primaryWhite,
              ),
            ),
            const SizedBox(height: 16),

            // Episode Details
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: BrandColors.grayMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  _episode!.duration,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.grayMedium,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.category,
                  size: 16,
                  color: BrandColors.grayMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  _episode!.category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.grayMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Descripción',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: BrandColors.primaryWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _episode!.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: BrandColors.grayMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Tags
            if (_episode!.tags.isNotEmpty) ...[
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BrandColors.primaryWhite,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _episode!.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BrandColors.primaryOrange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BrandColors.primaryOrange,
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
    );
  }
}