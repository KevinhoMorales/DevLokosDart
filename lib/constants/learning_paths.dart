/// Rutas de aprendizaje disponibles para cursos.
/// Organizadas por categoría para UI y filtros en Academia.
///
/// Uso: CourseFormScreen (admin), AcademyScreen (filtros).
class LearningPaths {
  static const int maxPerCourse = 5;
  static const int minPerCourse = 1;

  /// Lista plana de todas las rutas (para búsqueda, validación).
  static List<String> get allPaths {
    return categoryMap.values.expand((e) => e).toList();
  }

  /// Rutas por categoría para mostrar en el formulario de curso.
  /// Formato: (nombreCategoría, lista de rutas).
  static const List<(String, List<String>)> categories = [
    ('Desarrollo de Plataformas', [
      'Mobile',
      'Frontend',
      'Backend',
      'Web Full-Stack',
      'Cross-Platform',
    ]),
    ('Lenguajes & Frameworks', [
      'Flutter',
      'React / Next.js',
      'Swift / iOS',
      'Android / Kotlin',
      'Kotlin Multiplatform',
      'Node.js',
      'Python',
      'Java / Spring',
    ]),
    ('Datos & Cloud', [
      'Base de datos',
      'Firebase / Firestore',
      'Cloud',
      'AWS',
      'Google Cloud',
      'Serverless',
      'Docker',
      'Kubernetes',
    ]),
    ('DevOps & Calidad', [
      'DevOps',
      'CI / CD',
      'Testing',
      'Performance',
      'Monitoring',
    ]),
    ('IA & Automatización', [
      'IA / ML',
      'Prompt Engineering',
      'AI in Apps',
      'Automation',
    ]),
    ('Arquitectura & Producto', [
      'Software Architecture',
      'Clean Architecture',
      'Microservices',
      'UX / UI',
      'Product Management',
    ]),
  ];

  /// Mapa categoría -> rutas (para búsqueda rápida).
  static const Map<String, List<String>> categoryMap = {
    'Desarrollo de Plataformas': [
      'Mobile',
      'Frontend',
      'Backend',
      'Web Full-Stack',
      'Cross-Platform',
    ],
    'Lenguajes & Frameworks': [
      'Flutter',
      'React / Next.js',
      'Swift / iOS',
      'Android / Kotlin',
      'Kotlin Multiplatform',
      'Node.js',
      'Python',
      'Java / Spring',
    ],
    'Datos & Cloud': [
      'Base de datos',
      'Firebase / Firestore',
      'Cloud',
      'AWS',
      'Google Cloud',
      'Serverless',
      'Docker',
      'Kubernetes',
    ],
    'DevOps & Calidad': [
      'DevOps',
      'CI / CD',
      'Testing',
      'Performance',
      'Monitoring',
    ],
    'IA & Automatización': [
      'IA / ML',
      'Prompt Engineering',
      'AI in Apps',
      'Automation',
    ],
    'Arquitectura & Producto': [
      'Software Architecture',
      'Clean Architecture',
      'Microservices',
      'UX / UI',
      'Product Management',
    ],
  };

  /// Normaliza rutas legacy a las actuales (p.ej. "IA / ML" se mantiene).
  /// Útil al cargar cursos antiguos con rutas que ya no existen.
  static List<String> normalizePaths(List<String> paths) {
    final all = allPaths;
    return paths
        .where((p) => all.contains(p))
        .toList();
  }
}
