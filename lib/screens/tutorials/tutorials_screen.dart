import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/tutorial/tutorial_bloc_exports.dart';
import '../../models/tutorial.dart';
import '../../models/youtube_playlist_info.dart';
import '../../utils/app_haptics.dart';
import '../../utils/brand_colors.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/content_skeleton.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/section_header.dart';
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
  List<YouTubePlaylistInfo> _cachedPlaylists = const [];
  String? _cachedSelectedId;

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
      backgroundColor: BrandColors.primaryBlack,
      appBar: const CustomAppBar(title: ''),
      body: SafeArea(
        child: Column(
          children: [
            if (RemoteConfigService().isTutorialsPlaylistConfigured) ...[
              Padding(
                padding: Responsive.searchBarPadding(context),
                child: SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Buscar por título...',
                  onChanged: (value) {
                    context
                        .read<TutorialBloc>()
                        .add(SearchTutorials(value.trim()));
                  },
                  onSubmitted: (value) {
                    context
                        .read<TutorialBloc>()
                        .add(SearchTutorials(value.trim()));
                  },
                ),
              ),
              _buildPlaylistChips(),
            ],
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistChips() {
    return BlocBuilder<TutorialBloc, TutorialState>(
      builder: (context, state) {
        if (state is TutorialLoaded) {
          _cachedPlaylists = state.playlists;
          _cachedSelectedId = state.selectedPlaylistId;
        } else if (state is PlaylistsLoaded && state.playlists.isNotEmpty) {
          _cachedPlaylists = state.playlists;
        }

        final playlists = _cachedPlaylists;
        final selectedId = _cachedSelectedId;

        if (playlists.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final p = playlists[index];
              final isSelected = p.id == selectedId;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  _searchController.clear();
                  context.read<TutorialBloc>().add(SelectPlaylist(
                        playlistId: p.id,
                        playlistTitle: p.title,
                      ));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BrandColors.primaryOrange.withValues(alpha: 0.16)
                        : BrandColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? BrandColors.primaryOrange.withValues(alpha: 0.7)
                          : BrandColors.primaryOrange.withValues(alpha: 0.14),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.title,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.1,
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (!RemoteConfigService().isTutorialsPlaylistConfigured) {
      return const AppEmptyState(
        icon: Icons.playlist_add_outlined,
        title: 'Tutoriales próximamente',
        subtitle:
            'Estamos preparando contenido de tutoriales. Vuelve pronto.',
      );
    }

    return BlocBuilder<TutorialBloc, TutorialState>(
      builder: (context, state) {
        if (state is TutorialLoading) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: ContentSkeleton.card(count: 3),
          );
        }

        if (state is TutorialError) {
          return AppErrorState(
            message: state.message,
            onRetry: () =>
                context.read<TutorialBloc>().add(const LoadPlaylists()),
          );
        }

        if (state is TutorialLoaded) {
          final tutorials = state.filteredTutorials;
          final sectionTitle = state.selectedPlaylistTitle?.isNotEmpty == true
              ? state.selectedPlaylistTitle!
              : 'Tutoriales';

          if (state.isSwitching) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: sectionTitle,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  const Expanded(
                    child: ContentSkeleton.card(count: 3),
                  ),
                ],
              ),
            );
          }

          if (tutorials.isEmpty) {
            return AppEmptyState(
              icon: Icons.search_off_rounded,
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
                left: 20,
                right: 20,
                top: 4,
                bottom: MediaQuery.of(context).padding.bottom + 100,
              ),
              itemCount: tutorials.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionHeader(
                      title: sectionTitle,
                      padding: EdgeInsets.zero,
                      trailing: Text(
                        '${tutorials.length}',
                        style: const TextStyle(
                          color: BrandColors.grayMedium,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                final tutorial = tutorials[index - 1];
                return TutorialCard(
                  key: ValueKey(tutorial.id),
                  tutorial: tutorial,
                  compact: true,
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
          return const AppEmptyState(
            icon: Icons.playlist_remove,
            title: 'Sin playlists',
            subtitle: 'No hay playlists de tutoriales configuradas.',
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _onTutorialTap(Tutorial tutorial, String? playlistTitle) {
    final youtubeProvider = context.read<YouTubeProvider>();
    final video = youtubeProvider.getVideoById(tutorial.videoId);

    context.push(
      '/episode/${tutorial.id}',
      extra: {
        if (video != null) 'youtubeVideo': video,
        'playlistTitle': playlistTitle,
      },
    );
  }
}
