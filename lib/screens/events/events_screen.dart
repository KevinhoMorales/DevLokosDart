import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/event/event_bloc_exports.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(const LoadEvents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Eventos',
        showBackButton: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: BrandColors.primaryBlack,
        ),
        child: BlocBuilder<EventBloc, EventState>(
          builder: (context, state) {
            if (state is EventLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primaryOrange),
                ),
              );
            }

            if (state is EventError) {
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
                        child: const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: BrandColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Algo salió mal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: BrandColors.grayMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<EventBloc>().add(const RefreshEvents()),
                        icon: const Icon(Icons.refresh, color: BrandColors.primaryOrange),
                        label: const Text(
                          'Reintentar',
                          style: TextStyle(
                            color: BrandColors.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is EventLoaded) {
              if (state.events.isEmpty) {
                return _buildRefreshableEmptyState(context);
              }
              final upcoming =
                  state.events.where((e) => !e.isPast).toList();
              final past = state.events.where((e) => e.isPast).toList();

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<EventBloc>().add(const RefreshEvents());
                },
                color: BrandColors.primaryOrange,
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 32,
                  ),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      _buildSectionHeader('Próximos', Icons.schedule_rounded),
                      const SizedBox(height: 12),
                      ...upcoming.map(
                        (event) => EventCard(
                          event: event,
                          onTap: () => context.push(
                            '/events/${event.id}',
                            extra: {'event': event},
                          ),
                        ),
                      ),
                      if (past.isNotEmpty) const SizedBox(height: 24),
                    ],
                    if (past.isNotEmpty) ...[
                      _buildSectionHeader('Pasados', Icons.history_rounded),
                      const SizedBox(height: 12),
                      ...past.map(
                        (event) => EventCard(
                          event: event,
                          onTap: () => context.push(
                            '/events/${event.id}',
                            extra: {'event': event},
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return _buildRefreshableEmptyState(context);
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BrandColors.primaryOrange),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BrandColors.primaryWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshableEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<EventBloc>().add(const RefreshEvents());
      },
      color: BrandColors.primaryOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: _buildEmptyState(context),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              child: const Icon(
                Icons.event_available_outlined,
                size: 48,
                color: BrandColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Próximamente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: BrandColors.primaryWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos preparando eventos increíbles. ¡Vuelve pronto!',
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
}
