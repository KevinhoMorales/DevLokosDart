import 'package:flutter_test/flutter_test.dart';
import 'package:devlokos_podcast/constants/podcast_seasons.dart';

void main() {
  group('PodcastSeasons', () {
    test('default is Todas so latest episodes are visible', () {
      expect(PodcastSeasons.defaultLabel, PodcastSeasons.allLabel);
      expect(PodcastSeasons.labels.first, PodcastSeasons.allLabel);
    });

    test('detectFromTitle prefers S3 and ignores S10 as S1', () {
      expect(PodcastSeasons.detectFromTitle('DevLokos S3 Ep001'), 3);
      expect(PodcastSeasons.detectFromTitle('DevLokos S2 Ep065'), 2);
      expect(PodcastSeasons.detectFromTitle('DevLokos S1 Ep010'), 1);
      expect(PodcastSeasons.detectFromTitle('DevLokos S10 Ep100'), 2);
      expect(PodcastSeasons.detectFromTitle('Sin marcador'), 2);
    });

    test('newestSeasonWithContent picks highest season with items', () {
      expect(
        PodcastSeasons.newestSeasonWithContent(
          s1Count: 5,
          s2Count: 3,
          s3Count: 1,
        ),
        'Temporada 3',
      );
      expect(
        PodcastSeasons.newestSeasonWithContent(
          s1Count: 5,
          s2Count: 3,
          s3Count: 0,
        ),
        'Temporada 2',
      );
      expect(
        PodcastSeasons.newestSeasonWithContent(
          s1Count: 0,
          s2Count: 0,
          s3Count: 0,
        ),
        PodcastSeasons.allLabel,
      );
    });
  });
}
