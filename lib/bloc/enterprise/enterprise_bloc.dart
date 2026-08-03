import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(const EnterpriseError(
        message: 'No pudimos cargar los servicios. Revisa tu conexión e intenta de nuevo.',
      ));
    }
  }

  Future<void> _onLoadPortfolio(
    LoadPortfolio event,
    Emitter<EnterpriseState> emit,
  ) async {
    if (state is! EnterpriseLoaded) return;
    final currentState = state as EnterpriseLoaded;
    try {
      final portfolio = await _repository.getPortfolioProjects();
      emit(currentState.copyWith(portfolioProjects: portfolio));
    } catch (e) {
      emit(const EnterpriseError(
        message: 'No pudimos cargar el portafolio. Revisa tu conexión e intenta de nuevo.',
      ));
    }
  }

  Future<void> _onSubmitContactForm(
    SubmitContactForm event,
    Emitter<EnterpriseState> emit,
  ) async {
    // Mantener contenido visible mientras se envía
    final loaded = state is EnterpriseLoaded
        ? state as EnterpriseLoaded
        : const EnterpriseLoaded(services: [], portfolioProjects: []);

    try {
      AnalyticsService.logEnterpriseContactStarted();
      emit(loaded.copyWith(
        isSubmitting: true,
        clearSubmitError: true,
        clearSubmitSuccess: true,
      ));
      await _repository.submitContactForm(event.submission);
      AnalyticsService.logEnterpriseContactSubmitted(
        hasCompany: event.submission.company != null &&
            event.submission.company!.trim().isNotEmpty,
      );
      emit(loaded.copyWith(
        isSubmitting: false,
        submitSuccess: true,
        clearSubmitError: true,
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(loaded.copyWith(
        isSubmitting: false,
        submitError: message,
        clearSubmitSuccess: true,
      ));
    }
  }

  Future<void> _onSelectPortfolioProject(
    SelectPortfolioProject event,
    Emitter<EnterpriseState> emit,
  ) async {}
}
