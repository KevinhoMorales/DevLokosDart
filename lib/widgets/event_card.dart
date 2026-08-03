import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import '../utils/brand_colors.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  /// Destaca el primer próximo evento con más altura y énfasis.
  final bool featured;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = event.isPast;
    final height = featured ? 280.0 : 220.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPast
              ? Colors.white.withValues(alpha: 0.08)
              : BrandColors.primaryOrange.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.primaryOrange.withValues(alpha: isPast ? 0.04 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          enableFeedback: false,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(),
                // Gradiente inferior para legibilidad
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                // Acento naranja sutil arriba
                if (!isPast)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BrandColors.primaryOrange,
                            BrandColors.orangeLight,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.eventDate != null) _DateBadge(event: event),
                          const Spacer(),
                          _StatusChip(event: event),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        event.title,
                        style: TextStyle(
                          color: BrandColors.primaryWhite,
                          fontSize: featured ? 24 : 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.locationDisplay.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _MetaChip(
                          icon: Icons.location_on_rounded,
                          label: event.locationDisplay,
                        ),
                      ],
                      if (featured && !isPast) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Ver detalles',
                          style: TextStyle(
                            color: BrandColors.primaryOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (event.imageUrl.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1410),
              BrandColors.blackDark,
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.event_rounded,
            size: 72,
            color: BrandColors.primaryOrange.withValues(alpha: 0.25),
          ),
        ),
      );
    }

    final image = CachedNetworkImage(
      imageUrl: event.imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: BrandColors.blackLight),
      errorWidget: (context, url, error) => Container(
        color: BrandColors.blackLight,
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: BrandColors.grayMedium.withValues(alpha: 0.5),
        ),
      ),
    );

    if (!event.isPast) return image;

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF666666), BlendMode.saturation),
      child: image,
    );
  }
}

class _DateBadge extends StatelessWidget {
  final Event event;

  const _DateBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.dayLabel,
            style: const TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.monthLabel.toUpperCase(),
            style: const TextStyle(
              color: BrandColors.primaryOrange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Event event;

  const _StatusChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (event.isToday) {
      bg = BrandColors.primaryOrange;
      fg = BrandColors.primaryWhite;
    } else if (event.isPast) {
      bg = Colors.white.withValues(alpha: 0.12);
      fg = BrandColors.grayMedium;
    } else {
      bg = BrandColors.primaryOrange.withValues(alpha: 0.2);
      fg = BrandColors.primaryOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        event.statusLabel,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: BrandColors.primaryOrange),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: BrandColors.primaryWhite,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
