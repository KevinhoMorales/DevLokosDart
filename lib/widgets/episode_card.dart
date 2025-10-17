import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/episode.dart';
import '../utils/brand_colors.dart';

class EpisodeCard extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;

  const EpisodeCard({
    super.key,
    required this.episode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: BrandColors.blackLight.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BrandColors.primaryOrange.withOpacity(0.2),
          ),
          boxShadow: BrandColors.blackShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: episode.thumbnailUrl,
                    fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: BrandColors.primaryOrange.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              BrandColors.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: BrandColors.primaryOrange.withOpacity(0.1),
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: BrandColors.primaryOrange,
                          size: 32,
                        ),
                      ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primaryWhite,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BrandColors.grayMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: BrandColors.grayMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          episode.duration,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BrandColors.grayMedium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.category,
                          size: 14,
                          color: BrandColors.grayMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          episode.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BrandColors.grayMedium,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}