import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:devlokos_podcast/bloc/academy/academy_bloc_exports.dart';
import 'package:devlokos_podcast/models/course.dart';
import 'package:devlokos_podcast/repository/academy_repository.dart';

class MockAcademyRepository extends Mock implements AcademyRepository {}

Course _course({
  required String id,
  required String title,
  required String difficulty,
  required List<String> paths,
}) {
  final now = DateTime(2024, 1, 1);
  return Course(
    id: id,
    title: title,
    description: 'Desc $title',
    learningObjectives: const [],
    difficulty: difficulty,
    duration: 60,
    learningPaths: paths,
    modules: const [],
    createdAt: now,
    updatedAt: now,
    isPublished: true,
  );
}

void main() {
  group('AcademyBloc filters', () {
    late MockAcademyRepository repo;
    late List<Course> catalog;

    setUp(() {
      repo = MockAcademyRepository();
      catalog = [
        _course(
          id: '1',
          title: 'Flutter Avanzado',
          difficulty: 'Advanced',
          paths: ['Mobile'],
        ),
        _course(
          id: '2',
          title: 'Dart Básico',
          difficulty: 'Beginner',
          paths: ['Mobile'],
        ),
        _course(
          id: '3',
          title: 'Node API',
          difficulty: 'Intermediate',
          paths: ['Backend'],
        ),
      ];
    });

    blocTest<AcademyBloc, AcademyState>(
      'combines learning path and difficulty as AND',
      build: () {
        when(() => repo.getPublishedCourses())
            .thenAnswer((_) async => catalog);
        when(() => repo.getUpcomingCourses()).thenAnswer((_) async => []);
        return AcademyBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const LoadCourses());
        await bloc.stream.firstWhere((s) => s is AcademyLoaded);
        bloc.add(const FilterCoursesByLearningPath('Mobile'));
        await bloc.stream.first;
        bloc.add(const FilterCoursesByDifficulty('Beginner'));
      },
      skip: 1, // AcademyLoading
      expect: () => [
        isA<AcademyLoaded>()
            .having((s) => s.filteredCourses.length, 'all', 3),
        isA<AcademyLoaded>().having(
          (s) => s.filteredCourses.map((c) => c.id).toList(),
          'mobile only',
          ['1', '2'],
        ),
        isA<AcademyLoaded>().having(
          (s) => s.filteredCourses.map((c) => c.id).toList(),
          'mobile + beginner',
          ['2'],
        ),
      ],
    );

    blocTest<AcademyBloc, AcademyState>(
      'ClearFilters restores full catalog and null selections',
      build: () {
        when(() => repo.getPublishedCourses())
            .thenAnswer((_) async => catalog);
        when(() => repo.getUpcomingCourses()).thenAnswer((_) async => []);
        return AcademyBloc(repository: repo);
      },
      seed: () => AcademyLoaded(
        courses: catalog,
        filteredCourses: [catalog[1]],
        upcomingCourses: const [],
        selectedLearningPath: 'Mobile',
        selectedDifficulty: 'Beginner',
        searchQuery: 'dart',
      ),
      act: (bloc) => bloc.add(const ClearFilters()),
      expect: () => [
        isA<AcademyLoaded>()
            .having((s) => s.filteredCourses.length, 'count', 3)
            .having((s) => s.selectedLearningPath, 'path', null)
            .having((s) => s.selectedDifficulty, 'diff', null)
            .having((s) => s.searchQuery, 'query', ''),
      ],
    );
  });
}
