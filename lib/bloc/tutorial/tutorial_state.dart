import 'package:equatable/equatable.dart';
import '../../models/tutorial.dart';

abstract class TutorialState extends Equatable {
  const TutorialState();

  @override
  List<Object?> get props => [];
}

class TutorialInitial extends TutorialState {
  const TutorialInitial();
}

class TutorialLoading extends TutorialState {
  const TutorialLoading();
}

class TutorialLoaded extends TutorialState {
  final List<Tutorial> tutorials;
  final List<Tutorial> filteredTutorials;
  final String? selectedCategory;
  final String? selectedTechStack;
  final String? selectedLevel;
  final String searchQuery;

  const TutorialLoaded({
    required this.tutorials,
    required this.filteredTutorials,
    this.selectedCategory,
    this.selectedTechStack,
    this.selectedLevel,
    this.searchQuery = '',
  });

  TutorialLoaded copyWith({
    List<Tutorial>? tutorials,
    List<Tutorial>? filteredTutorials,
    String? selectedCategory,
    String? selectedTechStack,
    String? selectedLevel,
    String? searchQuery,
  }) {
    return TutorialLoaded(
      tutorials: tutorials ?? this.tutorials,
      filteredTutorials: filteredTutorials ?? this.filteredTutorials,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedTechStack: selectedTechStack ?? this.selectedTechStack,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        tutorials,
        filteredTutorials,
        selectedCategory,
        selectedTechStack,
        selectedLevel,
        searchQuery,
      ];
}

class TutorialError extends TutorialState {
  final String message;
  final List<Tutorial>? cachedTutorials;

  const TutorialError({
    required this.message,
    this.cachedTutorials,
  });

  @override
  List<Object?> get props => [message, cachedTutorials];
}

