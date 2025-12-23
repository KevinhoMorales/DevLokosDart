import 'package:equatable/equatable.dart';

abstract class AcademyEvent extends Equatable {
  const AcademyEvent();

  @override
  List<Object?> get props => [];
}

class LoadCourses extends AcademyEvent {
  const LoadCourses();
}

class RefreshCourses extends AcademyEvent {
  const RefreshCourses();
}

class LoadUpcomingCourses extends AcademyEvent {
  const LoadUpcomingCourses();
}

class FilterCoursesByLearningPath extends AcademyEvent {
  final String learningPath;

  const FilterCoursesByLearningPath(this.learningPath);

  @override
  List<Object?> get props => [learningPath];
}

class FilterCoursesByDifficulty extends AcademyEvent {
  final String difficulty;

  const FilterCoursesByDifficulty(this.difficulty);

  @override
  List<Object?> get props => [difficulty];
}

class SearchCourses extends AcademyEvent {
  final String query;

  const SearchCourses(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectCourse extends AcademyEvent {
  final String courseId;

  const SelectCourse(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

class ClearFilters extends AcademyEvent {
  const ClearFilters();
}

