import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/event.dart';
import '../../repository/event_repository.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final _repository = EventRepository();
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _repository.getAllEvents();
      setState(() {
        _events = _sortEvents(events);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar eventos: $e');
    }
  }

  List<Event> _sortEvents(List<Event> events) {
    final sorted = List<Event>.from(events);
    sorted.sort((a, b) {
      if (a.eventDate == null && b.eventDate == null) return 0;
      if (a.eventDate == null) return 1;
      if (b.eventDate == null) return -1;
      return a.eventDate!.compareTo(b.eventDate!);
    });
    return sorted;
  }

  void _onCreateEvent() {
    context.push('/admin/events/new').then((_) => _loadEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestión de Eventos',
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(color: BrandColors.primaryBlack),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
                  ),
                )
              : _events.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      color: BrandColors.primaryOrange,
                      child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _events.length,
                    itemBuilder: (context, index) =>
                        _buildEventCard(_events[index]),
                  ),
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateEvent,
        backgroundColor: BrandColors.primaryOrange,
        icon: const Icon(Icons.add, color: BrandColors.primaryWhite, size: 22),
        label: const Text(
          'Crear evento',
          style: TextStyle(
            color: BrandColors.primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 100),
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
              child: const Icon(
                Icons.event_outlined,
                size: 48,
                color: BrandColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay eventos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: BrandColors.primaryWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón de abajo para crear tu primer evento',
              style: TextStyle(
                fontSize: 15,
                color: BrandColors.grayMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: BrandColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandColors.primaryOrange.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.push('/admin/events/${event.id}').then((_) => _loadEvents()),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (event.imageUrl.isNotEmpty)
                    _buildCardImage(event.imageUrl)
                  else
                    _buildCardImagePlaceholder(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primaryWhite,
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
                                fontSize: 13,
                                color: BrandColors.grayMedium,
                              ),
                            ),
                          ],
                          if (event.formattedDate.isNotEmpty && event.locationDisplay.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                  fontSize: 13,
                                  color: BrandColors.grayMedium,
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

  Widget _buildCardImage(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildCardImagePlaceholder(),
          errorWidget: (_, __, ___) => _buildCardImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildCardImagePlaceholder() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: BrandColors.blackLight,
          child: const Center(
            child: Icon(
              Icons.event_rounded,
              color: BrandColors.grayMedium,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BrandColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
