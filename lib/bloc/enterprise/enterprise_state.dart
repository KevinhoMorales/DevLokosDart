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

  const EnterpriseLoaded({
    required this.services,
    required this.portfolioProjects,
  });

  EnterpriseLoaded copyWith({
    List<Service>? services,
    List<PortfolioProject>? portfolioProjects,
  }) {
    return EnterpriseLoaded(
      services: services ?? this.services,
      portfolioProjects: portfolioProjects ?? this.portfolioProjects,
    );
  }

  @override
  List<Object?> get props => [services, portfolioProjects];
}

class EnterpriseError extends EnterpriseState {
  final String message;

  const EnterpriseError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ContactFormSubmitting extends EnterpriseState {
  const ContactFormSubmitting();
}

class ContactFormSubmitted extends EnterpriseState {
  const ContactFormSubmitted();
}

class ContactFormError extends EnterpriseState {
  final String message;

  const ContactFormError({required this.message});

  @override
  List<Object?> get props => [message];
}


