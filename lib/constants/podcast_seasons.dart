/// Temporadas del podcast DevLokos.
/// Extensible: agregar entradas aquí para S4+ sin tocar la UI del selector.
class PodcastSeasons {
  PodcastSeasons._();

  static const List<PodcastSeason> all = [
    PodcastSeason(number: 1, label: 'Temporada 1', pattern: 'S1'),
    PodcastSeason(number: 2, label: 'Temporada 2', pattern: 'S2'),
    PodcastSeason(number: 3, label: 'Temporada 3', pattern: 'S3'),
  ];

  static const String defaultLabel = 'Temporada 2';

  static List<String> get labels => all.map((s) => s.label).toList();

  static PodcastSeason? byLabel(String label) {
    for (final s in all) {
      if (s.label == label) return s;
    }
    return null;
  }

  static PodcastSeason? byNumber(int number) {
    for (final s in all) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// Detecta temporada por substring en el título de YouTube (S3 > S2 > S1).
  /// Sin marcador → Temporada 2 (comportamiento histórico).
  static int detectFromTitle(String title) {
    if (title.contains('S3')) return 3;
    if (title.contains('S2')) return 2;
    if (title.contains('S1')) return 1;
    return 2;
  }

  static String patternForLabel(String label) =>
      byLabel(label)?.pattern ?? 'S2';

  static String emptyMessage(String label) {
    if (label == 'Temporada 3') {
      return 'Pronto episodios de Temporada 3. Mientras tanto, explora Temporada 1 o 2.';
    }
    return 'No hay episodios en $label por ahora.';
  }
}

class PodcastSeason {
  final int number;
  final String label;
  final String pattern;

  const PodcastSeason({
    required this.number,
    required this.label,
    required this.pattern,
  });
}
