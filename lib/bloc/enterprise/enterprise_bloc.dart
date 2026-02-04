import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/enterprise.dart';
import '../../repository/enterprise_repository.dart';
import '../../services/analytics_service.dart';
import 'enterprise_event.dart';
import 'enterprise_state.dart';

class EnterpriseBloc extends Bloc<EnterpriseEvent, EnterpriseState> {
  final EnterpriseRepository _repository;

  EnterpriseBloc({
    required EnterpriseRepository repository,
  })  : _repository = repository,
        super(const EnterpriseInitial()) {
    on<LoadServices>(_onLoadServices);
    on<LoadPortfolio>(_onLoadPortfolio);
    on<SubmitContactForm>(_onSubmitContactForm);
    on<SelectPortfolioProject>(_onSelectPortfolioProject);
  }

  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<EnterpriseState> emit,
  ) async {
    try {
      emit(const EnterpriseLoading());
      final services = await _repository.getServices();
      final portfolio = await _repository.getPortfolioProjects();
      emit(EnterpriseLoaded(
        services: services,
        portfolioProjects: portfolio,
      ));
    } catch (e) {
      emit(EnterpriseError(message: 'Error al cargar servicios: $e'));
    }
  }

  Future<void> _onLoadPortfolio(
    LoadPortfolio event,
    Emitter<EnterpriseState> emit,
  ) async {
    if (state is EnterpriseLoaded) {
      final currentState = state as EnterpriseLoaded;
      try {
        final portfolio = await _repository.getPortfolioProjects();
        emit(currentState.copyWith(portfolioProjects: portfolio));
      } catch (e) {
        emit(EnterpriseError(message: 'Error al cargar portfolio: $e'));
      }
    }
  }

  Future<void> _onSubmitContactForm(
    SubmitContactForm event,
    Emitter<EnterpriseState> emit,
  ) async {
    final previousState = state;
    try {
      AnalyticsService.logEnterpriseContactStarted();
      emit(const ContactFormSubmitting());
      await _repository.submitContactForm(event.submission);
      AnalyticsService.logEnterpriseContactSubmitted(
        hasCompany: event.submission.company != null &&
            event.submission.company!.trim().isNotEmpty,
      );
      emit(const ContactFormSubmitted());

      // Restaurar el estado anterior sin recargar (los datos no cambiaron)
      if (previousState is EnterpriseLoaded) {
        emit(EnterpriseLoaded(
          services: previousState.services,
          portfolioProjects: previousState.portfolioProjects,
        ));
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(ContactFormError(message: message));
    }
  }

  Future<void> _onSelectPortfolioProject(
    SelectPortfolioProject event,
    Emitter<EnterpriseState> emit,
  ) async {
    // Portfolio project selection logic can be handled here if needed
  }
}


