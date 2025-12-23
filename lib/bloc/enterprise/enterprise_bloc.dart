import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/enterprise.dart';
import '../../repository/enterprise_repository.dart';
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
    try {
      emit(const ContactFormSubmitting());
      await _repository.submitContactForm(event.submission);
      emit(const ContactFormSubmitted());
      
      // Reload services and portfolio after submission
      final services = await _repository.getServices();
      final portfolio = await _repository.getPortfolioProjects();
      emit(EnterpriseLoaded(
        services: services,
        portfolioProjects: portfolio,
      ));
    } catch (e) {
      emit(ContactFormError(message: 'Error al enviar formulario: $e'));
    }
  }

  Future<void> _onSelectPortfolioProject(
    SelectPortfolioProject event,
    Emitter<EnterpriseState> emit,
  ) async {
    // Portfolio project selection logic can be handled here if needed
  }
}

