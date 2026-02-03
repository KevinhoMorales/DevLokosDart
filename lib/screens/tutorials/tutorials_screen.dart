import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/tutorial/tutorial_bloc_exports.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/tutorial_card.dart';
import '../../models/tutorial.dart';
import 'package:provider/provider.dart';
import '../../providers/youtube_provider.dart';
import '../../screens/episode_detail/episode_detail_screen.dart';
import '../../services/remote_config_service.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedTechStack;
  String? _selectedLevel;

  final List<String> _categories = [
    'Backend',
    'Frontend',
    'Mobile',
    'DevOps',
    'AI',
    'Databases',
  ];

  final List<String> _levels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  List<String> _techStacks = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (RemoteConfigService().isTutorialsPlaylistConfigured) {
      context.read<TutorialBloc>().add(const LoadTutorials());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getTechStacksFromState(TutorialState state) {
    if (state is TutorialLoaded) {
      final stacks = <String>{};
      for (final t in state.tutorials) {
        stacks.addAll(t.techStack);
      }
      return stacks.toList()..sort();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<TutorialBloc, TutorialState>(
      listener: (context, state) {
        if (state is TutorialLoaded && mounted) {
          setState(() => _techStacks = _getTechStacksFromState(state));
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(title: ''),
        body: Container(
          decoration: const BoxDecoration(
            color: BrandColors.primaryBlack,
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (RemoteConfigService().isTutorialsPlaylistConfigured) ...[
                  _buildSearchBar(),
                  _buildFilters(),
                ],
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      child: SearchBarWidget(
        controller: _searchController,
        hintText: 'Buscar tutoriales por título, tecnología...',
        onChanged: (value) {
          context.read<TutorialBloc>().add(SearchTutorials(value.trim()));
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'Categoría',
              value: _selectedCategory,
              options: _categories,
              onSelected: (value) {
                setState(() {
                  _selectedCategory = value;
                });
                context.read<TutorialBloc>().add(
                      FilterTutorialsByCategory(value),
                    );
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Nivel',
              value: _selectedLevel,
              options: _levels,
              onSelected: (value) {
                setState(() {
                  _selectedLevel = value;
                });
                context.read<TutorialBloc>().add(
                      FilterTutorialsByLevel(value),
                    );
              },
            ),
            if (_techStacks.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Tecnología',
                value: _selectedTechStack,
                options: _techStacks,
                onSelected: (value) {
                  setState(() {
                    _selectedTechStack = value;
                  });
                  context.read<TutorialBloc>().add(
                        FilterTutorialsByTechStack(value),
                      );
                },
              ),
            ],
            if (_selectedCategory != null || _selectedLevel != null || _selectedTechStack != null) ...[
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Limpiar'),
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedLevel = null;
                    _selectedTechStack = null;
                  });
                  context.read<TutorialBloc>().add(const ClearTutorialFilters());
                },
                backgroundColor: BrandColors.cardBackground,
                labelStyle: const TextStyle(color: BrandColors.primaryWhite),
                side: const BorderSide(color: BrandColors.primaryOrange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null ? BrandColors.primaryOrange.withOpacity(0.2) : BrandColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null ? BrandColors.primaryOrange : BrandColors.grayMedium,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                color: value != null ? BrandColors.primaryOrange : BrandColors.primaryWhite,
                fontSize: 12,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: value != null ? BrandColors.primaryOrange : BrandColors.grayMedium,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onSelected: onSelected,
    );
  }

  Widget _buildContent() {
    if (!RemoteConfigService().isTutorialsPlaylistConfigured) {
      return _buildEmptyState(
        icon: Icons.playlist_add_outlined,
        title: 'Tutoriales próximamente',
        subtitle:
            'Estamos preparando contenido de tutoriales para ti. Cuando configuremos la playlist de YouTube, verás los videos aquí.',
      );
    }

    return BlocBuilder<TutorialBloc, TutorialState>(
      builder: (context, state) {
        if (state is TutorialLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
            ),
          );
        }

        if (state is TutorialError) {
          return _buildEmptyState(
            icon: Icons.playlist_play_outlined,
            title: 'No hay tutoriales disponibles',
            subtitle: state.message,
            showRetry: true,
            onRetry: () => context.read<TutorialBloc>().add(const RefreshTutorials()),
          );
        }

        if (state is TutorialLoaded) {
          final tutorials = state.filteredTutorials;

          if (tutorials.isEmpty) {
            return _buildEmptyState(
              icon: Icons.search_off,
              title: 'No se encontraron tutoriales',
              subtitle: 'Intenta con otros filtros o términos de búsqueda',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            itemCount: tutorials.length,
            itemBuilder: (context, index) {
              final tutorial = tutorials[index];
              return TutorialCard(
                tutorial: tutorial,
                onTap: () => _onTutorialTap(tutorial),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: BrandColors.grayMedium.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BrandColors.primaryWhite,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BrandColors.grayMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18, color: BrandColors.primaryOrange),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: BrandColors.primaryOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onTutorialTap(Tutorial tutorial) {
    final youtubeProvider = context.read<YouTubeProvider>();
    final video = youtubeProvider.getVideoById(tutorial.videoId);

    if (video != null) {
      context.push(
        '/episode/${tutorial.id}',
        extra: {'youtubeVideo': video},
      );
    } else {
      // Fallback: navegar solo con episodeId (EpisodeDetailScreen intentará cargar)
      context.push('/episode/${tutorial.id}');
    }
  }
}
