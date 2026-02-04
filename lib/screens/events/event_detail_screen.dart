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
      hasRegistrationLink: event.registrationUrl != null &&
          event.registrationUrl!.trim().isNotEmpty,
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
    return Scaffold(
      backgroundColor: BrandColors.primaryBlack,
      appBar: CustomAppBar(
        title: event.title.length > 30 ? '${event.title.substring(0, 27)}...' : event.title,
        showBackButton: true,
        iconActions: [
          AppBarIconAction(
            icon: Icons.share_rounded,
            onTap: (ctx) => _shareEvent(ctx, event),
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroImage(event),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.formattedDateTime.isNotEmpty || event.locationDisplay.isNotEmpty)
                      _buildMetaSection(context, event),
                    const SizedBox(height: 24),
                    if (event.description.isNotEmpty) ...[
                      Text(
                        'Descripción',
                        style: TextStyle(
                          color: BrandColors.primaryOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: BrandColors.grayLight,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (event.registrationUrl != null &&
                        event.registrationUrl!.isNotEmpty) ...[
                      GradientButton(
                        onPressed: () => _openRegistrationUrl(context, event),
                        text: 'Registrarme',
                        icon: Icons.arrow_forward_rounded,
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

  Widget _buildHeroImage(Event event) {
    if (event.imageUrl.isEmpty) {
      return Container(
        height: 200,
        color: BrandColors.blackLight,
        child: Center(
          child: Icon(
            Icons.event_rounded,
            size: 80,
            color: BrandColors.grayMedium.withOpacity(0.5),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: event.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: BrandColors.blackLight,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: BrandColors.blackLight,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: BrandColors.grayMedium.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaSection(BuildContext context, Event event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.blackLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (event.formattedDateTime.isNotEmpty)
            _buildMetaRow(
              Icons.calendar_today_rounded,
              event.formattedDateTime,
            ),
          if (event.formattedDateTime.isNotEmpty && event.locationDisplay.isNotEmpty)
            const SizedBox(height: 12),
          if (event.locationDisplay.isNotEmpty)
            _buildMetaRow(
              Icons.location_on_outlined,
              event.locationDisplay,
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: BrandColors.primaryOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: BrandColors.primaryWhite,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareEvent(BuildContext context, Event event) async {
    AnalyticsService.logEventShared(
      eventId: event.id,
      eventTitle: event.title,
    );
    try {
      final text = '${event.title}\n\n'
          '${event.formattedDate.isNotEmpty ? '📅 ${event.formattedDate}\n' : ''}'
          '${event.locationDisplay.isNotEmpty ? '📍 ${event.locationDisplay}\n' : ''}'
          '${event.registrationUrl ?? ''}';

      Rect sharePositionOrigin;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        sharePositionOrigin = Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
      } else {
        final size = MediaQuery.of(context).size;
        sharePositionOrigin = Rect.fromLTWH(size.width - 80, 0, 80, 80);
      }

      await Share.share(
        text.trim(),
        subject: event.title,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo compartir el evento'),
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
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace'),
              backgroundColor: BrandColors.error,
            ),
          );
        }
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
