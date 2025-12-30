import 'package:equatable/equatable.dart';

abstract class TutorialEvent extends Equatable {
  const TutorialEvent();

  @override
  List<Object?> get props => [];
}

class LoadTutorials extends TutorialEvent {
  const LoadTutorials();
}

class RefreshTutorials extends TutorialEvent {
  const RefreshTutorials();
}

class SearchTutorials extends TutorialEvent {
  final String query;

  const SearchTutorials(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterTutorialsByCategory extends TutorialEvent {
  final String category;

  const FilterTutorialsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class FilterTutorialsByTechStack extends TutorialEvent {
  final String techStack;

  const FilterTutorialsByTechStack(this.techStack);

  @override
  List<Object?> get props => [techStack];
}

class FilterTutorialsByLevel extends TutorialEvent {
  final String level;

  const FilterTutorialsByLevel(this.level);

  @override
  List<Object?> get props => [level];
}

class ClearTutorialFilters extends TutorialEvent {
  const ClearTutorialFilters();
}

class SelectTutorial extends TutorialEvent {
  final String tutorialId;

  const SelectTutorial(this.tutorialId);

  @override
  List<Object?> get props => [tutorialId];
}


