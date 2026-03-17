class StudentScore {
  final String id;
  final String fullName;
  final double? khmer;
  final double? civics;
  final double? history;
  final double? geography;
  final double? math;
  final double? physics;
  final double? chemistry;
  final double? biology;
  final double? earthScience;
  final double? foreignLanguage;
  final double? economics;
  final double? art;
  final double? pe;
  final double? chinese;

  const StudentScore({
    required this.id,
    required this.fullName,
    this.khmer,
    this.civics,
    this.history,
    this.geography,
    this.math,
    this.physics,
    this.chemistry,
    this.biology,
    this.earthScience,
    this.foreignLanguage,
    this.economics,
    this.art,
    this.pe,
    this.chinese,
  });

  bool get isFemale => fullName.startsWith('ក.') || fullName.startsWith('ម.');

  List<double?> get subjectValues => [
    khmer,
    civics,
    history,
    geography,
    math,
    physics,
    chemistry,
    biology,
    earthScience,
    foreignLanguage,
    economics,
    art,
    pe,
    chinese,
  ];

  Map<String, double?> get subjectMap => {
    'khmer': khmer,
    'civics': civics,
    'history': history,
    'geography': geography,
    'math': math,
    'physics': physics,
    'chemistry': chemistry,
    'biology': biology,
    'earthScience': earthScience,
    'foreignLanguage': foreignLanguage,
    'economics': economics,
    'art': art,
    'pe': pe,
    'chinese': chinese,
  };

  double get totalScore => subjectValues.fold<double>(
    0,
    (sum, value) => sum + _sanitizeScore(value),
  );

  double averageScore({double totalCoefficient = 15.5}) {
    if (totalCoefficient <= 0) {
      return 0;
    }
    return totalScore / totalCoefficient;
  }

  String get resultStatus => averageScore() >= 25.0 ? 'ជាប់' : 'ធ្លាក់';

  String mention({double totalCoefficient = 15.5}) {
    final average = averageScore(totalCoefficient: totalCoefficient);
    if (average >= 40.0) {
      return 'ល្អ';
    }
    if (average >= 32.5) {
      return 'ល្អបង្គួរ';
    }
    if (average >= 25.0) {
      return 'មធ្យម';
    }
    return 'ខ្សោយ';
  }

  StudentScore copyWith({
    String? id,
    String? fullName,
    double? khmer,
    double? civics,
    double? history,
    double? geography,
    double? math,
    double? physics,
    double? chemistry,
    double? biology,
    double? earthScience,
    double? foreignLanguage,
    double? economics,
    double? art,
    double? pe,
    double? chinese,
  }) {
    return StudentScore(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      khmer: khmer ?? this.khmer,
      civics: civics ?? this.civics,
      history: history ?? this.history,
      geography: geography ?? this.geography,
      math: math ?? this.math,
      physics: physics ?? this.physics,
      chemistry: chemistry ?? this.chemistry,
      biology: biology ?? this.biology,
      earthScience: earthScience ?? this.earthScience,
      foreignLanguage: foreignLanguage ?? this.foreignLanguage,
      economics: economics ?? this.economics,
      art: art ?? this.art,
      pe: pe ?? this.pe,
      chinese: chinese ?? this.chinese,
    );
  }

  static double _sanitizeScore(double? value) {
    if (value == null || value.isNaN || !value.isFinite) {
      return 0;
    }
    return value;
  }
}

class ClassSummary {
  final int totalStudents;
  final int femaleStudents;
  final Map<String, int> mentionCounts;

  ClassSummary({
    required this.totalStudents,
    required this.femaleStudents,
    required Map<String, int> mentionCounts,
  }) : mentionCounts = Map.unmodifiable({
         'ល្អ': mentionCounts['ល្អ'] ?? 0,
         'ល្អបង្គួរ': mentionCounts['ល្អបង្គួរ'] ?? 0,
         'មធ្យម': mentionCounts['មធ្យម'] ?? 0,
         'ខ្សោយ': mentionCounts['ខ្សោយ'] ?? 0,
       });

  factory ClassSummary.empty() {
    return ClassSummary(
      totalStudents: 0,
      femaleStudents: 0,
      mentionCounts: const {'ល្អ': 0, 'ល្អបង្គួរ': 0, 'មធ្យម': 0, 'ខ្សោយ': 0},
    );
  }
}
