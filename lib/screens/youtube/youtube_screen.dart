import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/youtube_provider.dart';
import '../../widgets/youtube_video_card.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/brand_colors.dart';

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<YouTubeProvider>().loadVideos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: const CustomAppBar(title: 'DevLokos Videos'),
      body: Consumer<YouTubeProvider>(
        builder: (context, youtubeProvider, child) {
          if (youtubeProvider.isLoading && youtubeProvider.videos.isEmpty) {
            return const _LoadingWidget();
          }

          if (youtubeProvider.errorMessage != null) {
            return _ErrorWidget(
              message: youtubeProvider.errorMessage!,
              onRetry: () => youtubeProvider.loadVideos(refresh: true),
            );
          }

          return Column(
            children: [
              // Search Bar
              _buildSearchBar(youtubeProvider),
              
              // Content
              Expanded(
                child: _isSearching
                    ? _buildSearchResults(youtubeProvider)
                    : _buildVideoList(youtubeProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<YouTubeProvider>().loadVideos(refresh: true);
        },
        backgroundColor: BrandColors.primaryOrange,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(YouTubeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: BrandColors.primaryWhite),
        decoration: InputDecoration(
          hintText: 'Buscar videos...',
          hintStyle: const TextStyle(color: BrandColors.grayMedium),
          prefixIcon: const Icon(Icons.search, color: BrandColors.primaryOrange),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: BrandColors.grayMedium),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                      _searchResults.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: BrandColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (query) => _performSearch(provider, query),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildVideoList(YouTubeProvider provider) {
    if (provider.videos.isEmpty) {
      return const _EmptyStateWidget();
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadVideos(refresh: true),
      color: BrandColors.primaryOrange,
      backgroundColor: BrandColors.cardBackground,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: provider.videos.length + (provider.hasMoreVideos ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.videos.length) {
            // Load more button
            return _buildLoadMoreButton(provider);
          }

          final video = provider.videos[index];
          return YouTubeVideoCard(
            video: video,
            onTap: () => _onVideoTap(video),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(YouTubeProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadVideos(refresh: true),
      color: BrandColors.primaryOrange,
      backgroundColor: BrandColors.cardBackground,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final video = _searchResults[index];
          return YouTubeVideoCard(
            video: video,
            onTap: () => _onVideoTap(video),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton(YouTubeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: BrandColors.primaryOrange,
              ),
            )
          : ElevatedButton(
              onPressed: () => provider.loadMoreVideos(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cargar más videos'),
            ),
    );
  }

  Future<void> _performSearch(YouTubeProvider provider, String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await provider.searchVideos(query.trim());
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la búsqueda: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onVideoTap(video) {
    // TODO: Implementar navegación al video
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reproduciendo: ${video.title}'),
        backgroundColor: BrandColors.primaryOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: BrandColors.primaryOrange,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando videos de YouTube...',
            style: TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: BrandColors.primaryOrange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar videos',
              style: const TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: BrandColors.grayMedium,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: BrandColors.primaryOrange,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No hay videos disponibles',
            style: TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Verifica tu conexión a internet o la configuración de la API',
            style: TextStyle(
              color: BrandColors.grayMedium,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
