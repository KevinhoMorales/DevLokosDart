import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/event/event_bloc_exports.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading.dart';
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
      backgroundColor: BrandColors.primaryBlack,
      appBar: const CustomAppBar(
        title: 'Eventos',
        showBackButton: true,
      ),
      body: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          if (state is EventLoading) {
            return const AppLoading(message: 'Cargando eventos...');
          }

          if (state is EventError) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Algo salió mal',
              subtitle: state.message,
              showRetry: true,
              onRetry: () => context.read<EventBloc>().add(const LoadEvents()),
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
    return const AppEmptyState(
      icon: Icons.event_available_outlined,
      title: 'Próximamente',
      subtitle: 'Estamos preparando eventos increíbles. ¡Vuelve pronto!',
    );
  }
}
