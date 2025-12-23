import 'package:equatable/equatable.dart';
import '../../models/course.dart';

abstract class AcademyState extends Equatable {
  const AcademyState();

  @override
  List<Object?> get props => [];
}

class AcademyInitial extends AcademyState {
  const AcademyInitial();
}

class AcademyLoading extends AcademyState {
  const AcademyLoading();
}

class AcademyLoaded extends AcademyState {
  final List<Course> courses;
  final List<Course> filteredCourses;
  final List<Course> upcomingCourses;
  final String? selectedLearningPath;
  final String? selectedDifficulty;
  final String searchQuery;
  final bool showUpcoming;

  const AcademyLoaded({
    required this.courses,
    required this.filteredCourses,
    required this.upcomingCourses,
    this.selectedLearningPath,
    this.selectedDifficulty,
    this.searchQuery = '',
    this.showUpcoming = false,
  });

  AcademyLoaded copyWith({
    List<Course>? courses,
    List<Course>? filteredCourses,
    List<Course>? upcomingCourses,
    String? selectedLearningPath,
    String? selectedDifficulty,
    String? searchQuery,
    bool? showUpcoming,
  }) {
    return AcademyLoaded(
      courses: courses ?? this.courses,
      filteredCourses: filteredCourses ?? this.filteredCourses,
      upcomingCourses: upcomingCourses ?? this.upcomingCourses,
      selectedLearningPath: selectedLearningPath ?? this.selectedLearningPath,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      searchQuery: searchQuery ?? this.searchQuery,
      showUpcoming: showUpcoming ?? this.showUpcoming,
    );
  }

  @override
  List<Object?> get props => [
        courses,
        filteredCourses,
        upcomingCourses,
        selectedLearningPath,
        selectedDifficulty,
        searchQuery,
        showUpcoming,
      ];
}

class AcademyError extends AcademyState {
  final String message;
  final List<Course>? cachedCourses;

  const AcademyError({
    required this.message,
    this.cachedCourses,
  });

  @override
  List<Object?> get props => [message, cachedCourses];
}

