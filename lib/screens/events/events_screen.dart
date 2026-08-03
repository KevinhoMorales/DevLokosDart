import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/event/event_bloc_exports.dart';
import '../../models/event.dart';
import '../../utils/brand_colors.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/event_card.dart';
import '../../widgets/section_header.dart';

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

  void _openEvent(Event event) {
    context.push('/events/${event.id}', extra: {'event': event});
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
            final upcoming = state.events.where((e) => !e.isPast).toList();
            final past = state.events.where((e) => e.isPast).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<EventBloc>().add(const RefreshEvents());
              },
              color: BrandColors.primaryOrange,
              backgroundColor: BrandColors.cardBackground,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Text(
                        'Meetups, charlas y talleres de la comunidad DevLokos. Reserva tu lugar o revive lo que ya pasó.',
                        style: TextStyle(
                          color: BrandColors.grayMedium,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (upcoming.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Próximos',
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: upcoming.length,
                        itemBuilder: (context, index) {
                          final event = upcoming[index];
                          return EventCard(
                            event: event,
                            featured: index == 0,
                            onTap: () => _openEvent(event),
                          );
                        },
                      ),
                    ),
                  ],
                  if (past.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'Pasados',
                        padding: EdgeInsets.fromLTRB(
                          20,
                          upcoming.isNotEmpty ? 8 : 16,
                          20,
                          12,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.of(context).padding.bottom + 28,
                      ),
                      sliver: SliverList.builder(
                        itemCount: past.length,
                        itemBuilder: (context, index) {
                          final event = past[index];
                          return EventCard(
                            event: event,
                            onTap: () => _openEvent(event),
                          );
                        },
                      ),
                    ),
                  ] else
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 28,
                      ),
                    ),
                ],
              ),
            );
          }

          return _buildRefreshableEmptyState(context);
        },
      ),
    );
  }

  Widget _buildRefreshableEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<EventBloc>().add(const RefreshEvents());
      },
      color: BrandColors.primaryOrange,
      backgroundColor: BrandColors.cardBackground,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: const AppEmptyState(
            icon: Icons.event_available_outlined,
            title: 'Próximamente',
            subtitle: 'Estamos preparando eventos increíbles. ¡Vuelve pronto!',
          ),
        ),
      ),
    );
  }
}
