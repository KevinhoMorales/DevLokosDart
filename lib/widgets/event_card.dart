import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import '../utils/brand_colors.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl.isNotEmpty) _buildImage(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.formattedDate.isNotEmpty || event.locationDisplay.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (event.formattedDate.isNotEmpty) ...[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: BrandColors.primaryOrange.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              event.formattedDate,
                              style: TextStyle(
                                color: BrandColors.grayMedium,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (event.formattedDate.isNotEmpty && event.locationDisplay.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: BrandColors.grayMedium,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (event.locationDisplay.isNotEmpty) ...[
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: BrandColors.primaryOrange.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.locationDisplay,
                                style: TextStyle(
                                  color: BrandColors.grayMedium,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: event.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: BrandColors.blackLight,
            child: Center(
              child: Icon(
                Icons.event_rounded,
                size: 48,
                color: BrandColors.grayMedium.withOpacity(0.5),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: BrandColors.blackLight,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: BrandColors.grayMedium.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
