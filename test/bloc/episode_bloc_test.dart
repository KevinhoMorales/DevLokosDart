import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:devlokos_podcast/bloc/episode/episode_bloc_exports.dart';
import 'package:devlokos_podcast/models/episode.dart';
import 'package:devlokos_podcast/repository/episode_repository.dart';

/// Mock del repositorio para testing
class MockEpisodeRepository extends Mock implements EpisodeRepository {}

void main() {
  group('EpisodeBloc', () {
    late EpisodeBloc episodeBloc;
    late MockEpisodeRepository mockRepository;

    setUp(() {
      mockRepository = MockEpisodeRepository();
      episodeBloc = EpisodeBloc(repository: mockRepository);
    });

    tearDown(() {
      episodeBloc.close();
    });

    test('initial state is EpisodeInitial', () {
      expect(episodeBloc.state, equals(const EpisodeInitial()));
    });

    group('LoadEpisodes', () {
      final testEpisodes = [
        Episode(
          id: '1',
          title: 'Test Episode 1',
          description: 'Test Description 1',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          youtubeVideoId: 'video1',
          duration: '10:00',
          publishedDate: DateTime(2024, 1, 1),
          category: 'Test',
          tags: ['test'],
          isFeatured: true,
        ),
        Episode(
          id: '2',
          title: 'Test Episode 2',
          description: 'Test Description 2',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          youtubeVideoId: 'video2',
          duration: '15:00',
          publishedDate: DateTime(2024, 1, 2),
          category: 'Test',
          tags: ['test'],
          isFeatured: false,
        ),
      ];

      blocTest<EpisodeBloc, EpisodeState>(
        'emits [EpisodeLoading, EpisodeLoaded] when LoadEpisodes is successful',
        build: () {
          when(() => mockRepository.getAllEpisodes())
              .thenAnswer((_) async => testEpisodes);
          return episodeBloc;
        },
        act: (bloc) => bloc.add(const LoadEpisodes()),
        expect: () => [
          const EpisodeLoading(),
          EpisodeLoaded(
            episodes: testEpisodes,
            featuredEpisodes: [testEpisodes[0]], // Solo el primero es featured
            filteredEpisodes: testEpisodes,
            searchQuery: '',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.getAllEpisodes()).called(1);
        },
      );

      blocTest<EpisodeBloc, EpisodeState>(
        'emits [EpisodeLoading, EpisodeError] when LoadEpisodes fails',
        build: () {
          when(() => mockRepository.getAllEpisodes())
              .thenThrow(Exception('Test error'));
          return episodeBloc;
        },
        act: (bloc) => bloc.add(const LoadEpisodes()),
        expect: () => [
          const EpisodeLoading(),
          const EpisodeError(message: 'Error al cargar episodios: Exception: Test error'),
        ],
        verify: (_) {
          verify(() => mockRepository.getAllEpisodes()).called(1);
        },
      );
    });

    group('SearchEpisodes', () {
      final testEpisodes = [
        Episode(
          id: '1',
          title: 'Flutter Tutorial',
          description: 'Learn Flutter',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          youtubeVideoId: 'video1',
          duration: '10:00',
          publishedDate: DateTime(2024, 1, 1),
          category: 'Flutter',
          tags: ['flutter', 'dart'],
          isFeatured: true,
        ),
        Episode(
          id: '2',
          title: 'React Native Guide',
          description: 'Learn React Native',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          youtubeVideoId: 'video2',
          duration: '15:00',
          publishedDate: DateTime(2024, 1, 2),
          category: 'React',
          tags: ['react', 'javascript'],
          isFeatured: false,
        ),
      ];

      blocTest<EpisodeBloc, EpisodeState>(
        'emits EpisodeSearching then EpisodeLoaded with filtered results',
        build: () {
          when(() => mockRepository.getAllEpisodes())
              .thenAnswer((_) async => testEpisodes);
          when(() => mockRepository.searchEpisodes('flutter'))
              .thenAnswer((_) async => [testEpisodes[0]]);
          return episodeBloc;
        },
        seed: () => EpisodeLoaded(
          episodes: testEpisodes,
          featuredEpisodes: [testEpisodes[0]], // El primer episodio es featured
          filteredEpisodes: testEpisodes,
          searchQuery: '',
        ),
        act: (bloc) => bloc.add(const SearchEpisodes(query: 'flutter')),
        expect: () => [
          EpisodeSearching(
            query: 'flutter',
            episodes: testEpisodes,
          ),
          EpisodeLoaded(
            episodes: testEpisodes,
            featuredEpisodes: [testEpisodes[0]], // Mantener featured episodes
            filteredEpisodes: [testEpisodes[0]],
            searchQuery: 'flutter',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.searchEpisodes('flutter')).called(1);
        },
      );
    });

    group('ClearSearch', () {
      final testEpisodes = [
        Episode(
          id: '1',
          title: 'Test Episode',
          description: 'Test Description',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          youtubeVideoId: 'video1',
          duration: '10:00',
          publishedDate: DateTime(2024, 1, 1),
          category: 'Test',
          tags: ['test'],
          isFeatured: true,
        ),
      ];

      blocTest<EpisodeBloc, EpisodeState>(
        'clears search query and shows all episodes',
        build: () => episodeBloc,
        seed: () => EpisodeLoaded(
          episodes: testEpisodes,
          featuredEpisodes: [testEpisodes[0]],
          filteredEpisodes: testEpisodes,
          searchQuery: 'test',
        ),
        act: (bloc) => bloc.add(const ClearSearch()),
        expect: () => [
          EpisodeLoaded(
            episodes: testEpisodes,
            featuredEpisodes: [testEpisodes[0]],
            filteredEpisodes: testEpisodes,
            searchQuery: '',
          ),
        ],
      );
    });
  });
}
