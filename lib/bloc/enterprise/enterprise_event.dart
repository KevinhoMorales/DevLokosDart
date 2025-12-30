import 'package:equatable/equatable.dart';
import '../../models/enterprise.dart';

abstract class EnterpriseEvent extends Equatable {
  const EnterpriseEvent();

  @override
  List<Object?> get props => [];
}

class LoadServices extends EnterpriseEvent {
  const LoadServices();
}

class LoadPortfolio extends EnterpriseEvent {
  const LoadPortfolio();
}

class SubmitContactForm extends EnterpriseEvent {
  final ContactSubmission submission;

  const SubmitContactForm(this.submission);

  @override
  List<Object?> get props => [submission];
}

class SelectPortfolioProject extends EnterpriseEvent {
  final String projectId;

  const SelectPortfolioProject(this.projectId);

  @override
  List<Object?> get props => [projectId];
}


