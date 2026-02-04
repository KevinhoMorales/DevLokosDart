import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/tutorial/tutorial_bloc_exports.dart';
import '../../models/tutorial.dart';
import '../../models/youtube_playlist_info.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/tutorial_card.dart';
import '../../providers/youtube_provider.dart';
import '../../services/remote_config_service.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (RemoteConfigService().isTutorialsPlaylistConfigured) {
      context.read<TutorialBloc>().add(const LoadPlaylists());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          child: Column(
            children: [
              if (RemoteConfigService().isTutorialsPlaylistConfigured) ...[
                _buildSearchBar(),
                _buildPlaylistChips(),
              ],
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SearchBarWidget(
        controller: _searchController,
        hintText: 'Buscar por título...',
        onChanged: (value) {
          context.read<TutorialBloc>().add(SearchTutorials(value.trim()));
        },
        onSubmitted: (value) {
          context.read<TutorialBloc>().add(SearchTutorials(value.trim()));
        },
      ),
    );
  }

  Widget _buildPlaylistChips() {
    return BlocBuilder<TutorialBloc, TutorialState>(
      buildWhen: (prev, curr) =>
          curr is PlaylistsLoaded ||
          curr is TutorialLoaded ||
          curr is TutorialLoading,
      builder: (context, state) {
        List<YouTubePlaylistInfo> playlists = [];
        String? selectedId;

        if (state is TutorialLoaded) {
          playlists = state.playlists;
          selectedId = state.selectedPlaylistId;
        } else if (state is PlaylistsLoaded) {
          playlists = state.playlists;
        }

        if (playlists.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final p = playlists[index];
              final isSelected = p.id == selectedId;
              return GestureDetector(
                onTap: () {
                  context.read<TutorialBloc>().add(SelectPlaylist(
                        playlistId: p.id,
                        playlistTitle: p.title,
                      ));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BrandColors.primaryOrange.withOpacity(0.25)
                        : BrandColors.cardBackground,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? BrandColors.primaryOrange
                          : BrandColors.grayMedium.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      p.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? BrandColors.primaryOrange
                            : BrandColors.grayLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (!RemoteConfigService().isTutorialsPlaylistConfigured) {
      return _buildEmptyState(
        icon: Icons.playlist_add_outlined,
        title: 'Tutoriales próximamente',
        subtitle:
            'Estamos preparando contenido de tutoriales. Cuando configuremos las playlists, verás los videos aquí.',
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
            onRetry: () => context.read<TutorialBloc>().add(const LoadPlaylists()),
          );
        }

        if (state is TutorialLoaded) {
          final tutorials = state.filteredTutorials;

          if (tutorials.isEmpty) {
            return _buildEmptyState(
              icon: Icons.search_off,
              title: 'No se encontraron tutoriales',
              subtitle: state.searchQuery.isNotEmpty
                  ? 'Intenta con otros términos de búsqueda'
                  : 'Esta playlist no tiene videos',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TutorialBloc>().add(const RefreshTutorials());
            },
            color: BrandColors.primaryOrange,
            child: ListView.builder(
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
                  onTap: () => _onTutorialTap(
                    tutorial,
                    state.selectedPlaylistTitle,
                  ),
                );
              },
            ),
          );
        }

        if (state is PlaylistsLoaded && state.playlists.isEmpty) {
          return _buildEmptyState(
            icon: Icons.playlist_remove,
            title: 'Sin playlists',
            subtitle: 'No hay playlists de tutoriales configuradas.',
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
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: BrandColors.primaryOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: BrandColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: BrandColors.primaryWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
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

  void _onTutorialTap(Tutorial tutorial, String? playlistTitle) {
    final youtubeProvider = context.read<YouTubeProvider>();
    final video = youtubeProvider.getVideoById(tutorial.videoId);

    if (video != null) {
      context.push(
        '/episode/${tutorial.id}',
        extra: {
          'youtubeVideo': video,
          'playlistTitle': playlistTitle,
        },
      );
    } else {
      context.push(
        '/episode/${tutorial.id}',
        extra: {'playlistTitle': playlistTitle},
      );
    }
  }
}
