/// Temporadas del podcast DevLokos.
/// Extensible: agregar entradas aquí para S4+ sin tocar la UI del selector.
class PodcastSeasons {
  PodcastSeasons._();

  static const List<PodcastSeason> all = [
    PodcastSeason(number: 1, label: 'Temporada 1', pattern: 'S1'),
    PodcastSeason(number: 2, label: 'Temporada 2', pattern: 'S2'),
    PodcastSeason(number: 3, label: 'Temporada 3', pattern: 'S3'),
  ];

  /// Filtro sin temporada: muestra todos los episodios (más recientes primero).
  static const String allLabel = 'Todas';

  /// Por defecto: todas las temporadas para que el último episodio sea visible.
  static const String defaultLabel = allLabel;

  static List<String> get labels => [allLabel, ...all.map((s) => s.label)];

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

  static bool isAll(String label) => label == allLabel;

  /// Detecta temporada por marcador en el título (S3 > S2 > S1).
  /// Usa límites de palabra para evitar que "S10" coincida con "S1".
  /// Sin marcador → Temporada 2 (comportamiento histórico).
  static int detectFromTitle(String title) {
    final upper = title.toUpperCase();
    if (RegExp(r'\bS3\b').hasMatch(upper)) return 3;
    if (RegExp(r'\bS2\b').hasMatch(upper)) return 2;
    if (RegExp(r'\bS1\b').hasMatch(upper)) return 1;
    return 2;
  }

  static String patternForLabel(String label) =>
      byLabel(label)?.pattern ?? 'S2';

  /// Elige la temporada más reciente que tenga episodios; si ninguna, [allLabel].
  static String newestSeasonWithContent({
    required int s1Count,
    required int s2Count,
    required int s3Count,
  }) {
    if (s3Count > 0) return byNumber(3)!.label;
    if (s2Count > 0) return byNumber(2)!.label;
    if (s1Count > 0) return byNumber(1)!.label;
    return allLabel;
  }

  static String emptyMessage(String label) {
    if (isAll(label)) {
      return 'No hay episodios por ahora. Desliza para actualizar.';
    }
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
