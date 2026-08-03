import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event.dart';
import '../../repository/event_repository.dart';
import '../../services/analytics_service.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart' show AppBarIconAction, CustomAppBar;
import '../../widgets/gradient_button.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final Event? event;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    if (_event == null) {
      _loadEvent();
    } else {
      _isLoading = false;
      _logEventViewed(_event!);
    }
  }

  void _logEventViewed(Event event) {
    AnalyticsService.logEventViewed(
      eventId: event.id,
      eventTitle: event.title,
      city: event.city.isNotEmpty ? event.city : null,
      hasRegistrationLink:
          event.registrationUrl != null && event.registrationUrl!.trim().isNotEmpty,
    );
  }

  Future<void> _loadEvent() async {
    final event = await EventRepository().getEventById(widget.eventId);
    if (mounted) {
      setState(() {
        _event = event;
        _isLoading = false;
        _error = event == null ? 'Evento no encontrado' : null;
      });
      if (event != null) {
        _logEventViewed(event);
      }
    }
  }

  bool get _hasRegistration {
    final url = _event?.registrationUrl;
    return url != null && url.trim().isNotEmpty && !(_event?.isPast ?? true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(title: 'Evento', showBackButton: true),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
          ),
        ),
      );
    }

    if (_event == null || _error != null) {
      return Scaffold(
        backgroundColor: BrandColors.primaryBlack,
        appBar: const CustomAppBar(title: 'Evento', showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _error ?? 'Evento no encontrado',
              style: const TextStyle(color: BrandColors.grayMedium),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final event = _event!;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: '',
        showBackButton: true,
        iconActions: [
          AppBarIconAction(
            icon: Icons.share_rounded,
            onTap: (ctx) => _shareEvent(ctx, event),
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero(event)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: BrandColors.primaryBlack,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      28,
                      24,
                      _hasRegistration ? 120 + bottomInset : 32 + bottomInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusRow(event),
                        const SizedBox(height: 16),
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: BrandColors.primaryWhite,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildMetaGrid(event),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          const Row(
                            children: [
                              SizedBox(
                                width: 4,
                                height: 18,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: BrandColors.primaryOrange,
                                    borderRadius: BorderRadius.all(Radius.circular(2)),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Sobre el evento',
                                style: TextStyle(
                                  color: BrandColors.primaryWhite,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            style: const TextStyle(
                              color: BrandColors.grayLight,
                              fontSize: 16,
                              height: 1.65,
                            ),
                          ),
                        ],
                        if (event.isPast) ...[
                          const SizedBox(height: 28),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BrandColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: BrandColors.primaryOrange,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Este evento ya terminó. Explora los próximos para no perderte el siguiente.',
                                    style: TextStyle(
                                      color: BrandColors.grayMedium,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_hasRegistration)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyCta(event, bottomInset),
            ),
        ],
      ),
    );
  }

  Widget _buildHero(Event event) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 320 + topPad * 0.3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (event.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: event.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: BrandColors.blackLight),
              errorWidget: (_, __, ___) => _heroFallback(),
            )
          else
            _heroFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          if (event.eventDate != null)
            Positioned(
              left: 24,
              bottom: 44,
              child: _HeroDateBadge(event: event),
            ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1810), BrandColors.blackDark, Colors.black],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_rounded,
          size: 88,
          color: BrandColors.primaryOrange.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildStatusRow(Event event) {
    final Color bg;
    final Color fg;
    if (event.isToday) {
      bg = BrandColors.primaryOrange;
      fg = BrandColors.primaryWhite;
    } else if (event.isPast) {
      bg = Colors.white.withValues(alpha: 0.1);
      fg = BrandColors.grayMedium;
    } else {
      bg = BrandColors.primaryOrange.withValues(alpha: 0.18);
      fg = BrandColors.primaryOrange;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          event.statusLabel,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaGrid(Event event) {
    final items = <({IconData icon, String label, String value})>[];
    if (event.formattedDateTime.isNotEmpty) {
      items.add((
        icon: Icons.calendar_month_rounded,
        label: 'Fecha',
        value: event.formattedDateTime,
      ));
    }
    if (event.locationDisplay.isNotEmpty) {
      items.add((
        icon: Icons.location_on_rounded,
        label: 'Lugar',
        value: event.locationDisplay,
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.map((item) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrandColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BrandColors.primaryOrange.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: BrandColors.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: BrandColors.primaryOrange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: BrandColors.grayMedium,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: BrandColors.primaryWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStickyCta(Event event, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
      decoration: BoxDecoration(
        color: BrandColors.primaryBlack.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: GradientButton(
        onPressed: () => _openRegistrationUrl(context, event),
        text: 'Registrarme',
        width: double.infinity,
      ),
    );
  }

  Future<void> _shareEvent(BuildContext context, Event event) async {
    AnalyticsService.logEventShared(
      eventId: event.id,
      eventTitle: event.title,
    );
    try {
      final text = '${event.title}\n\n'
          '${event.formattedDate.isNotEmpty ? '${event.formattedDate}\n' : ''}'
          '${event.locationDisplay.isNotEmpty ? '${event.locationDisplay}\n' : ''}'
          '${event.registrationUrl ?? ''}';

      Rect sharePositionOrigin;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        sharePositionOrigin =
            Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
      } else {
        final size = MediaQuery.of(context).size;
        sharePositionOrigin = Rect.fromLTWH(size.width - 80, 0, 80, 80);
      }

      await Share.share(
        text.trim(),
        subject: event.title,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir el evento'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openRegistrationUrl(BuildContext context, Event event) async {
    final url = event.registrationUrl;
    if (url == null || url.isEmpty) return;

    AnalyticsService.logEventRegisterClicked(
      eventId: event.id,
      eventTitle: event.title,
    );
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'),
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
  }
}

class _HeroDateBadge extends StatelessWidget {
  final Event event;

  const _HeroDateBadge({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.dayLabel,
            style: const TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.monthLabel.toUpperCase(),
            style: const TextStyle(
              color: BrandColors.primaryOrange,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
