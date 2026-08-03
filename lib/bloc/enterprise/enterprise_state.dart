import 'package:equatable/equatable.dart';
import '../../models/enterprise.dart';

abstract class EnterpriseState extends Equatable {
  const EnterpriseState();

  @override
  List<Object?> get props => [];
}

class EnterpriseInitial extends EnterpriseState {
  const EnterpriseInitial();
}

class EnterpriseLoading extends EnterpriseState {
  const EnterpriseLoading();
}

class EnterpriseLoaded extends EnterpriseState {
  final List<Service> services;
  final List<PortfolioProject> portfolioProjects;
  final bool isSubmitting;
  final String? submitError;
  final bool submitSuccess;

  const EnterpriseLoaded({
    required this.services,
    required this.portfolioProjects,
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess = false,
  });

  EnterpriseLoaded copyWith({
    List<Service>? services,
    List<PortfolioProject>? portfolioProjects,
    bool? isSubmitting,
    String? submitError,
    bool? submitSuccess,
    bool clearSubmitError = false,
    bool clearSubmitSuccess = false,
  }) {
    return EnterpriseLoaded(
      services: services ?? this.services,
      portfolioProjects: portfolioProjects ?? this.portfolioProjects,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitSuccess:
          clearSubmitSuccess ? false : (submitSuccess ?? this.submitSuccess),
    );
  }

  @override
  List<Object?> get props => [
        services,
        portfolioProjects,
        isSubmitting,
        submitError,
        submitSuccess,
      ];
}

class EnterpriseError extends EnterpriseState {
  final String message;

  const EnterpriseError({required this.message});

  @override
  List<Object?> get props => [message];
}
