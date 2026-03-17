import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';

const List<String> kAdviserDefaultSubjects = [
  'ភាសាខ្មែរ',
  'សីលធម៏័-ពលរដ្ធវិជ្ជា',
  'ប្រវត្តិវិទ្យា',
  'ភូមិវិទ្យា',
  'គណិតវិទ្យា',
  'រូបវិទ្យា',
  'គីមីវិទ្យា',
  'ជីវិទ្យា',
  'ផែនដីវិទ្យា',
  'ភាសាបរទេស',
  'បច្ចេកវិទ្យា',
  'គេហវិទ្យា',
  'អប់រំសិល្បៈ',
  'អប់រំកាយ កីឡា',
];

final subjectRepositoryProvider = Provider((ref) => SubjectRepository());

final subjectNotifierProvider =
    AsyncNotifierProvider<SubjectNotifier, List<SubjectModel>>(() {
      return SubjectNotifier();
    });

class SubjectNotifier extends AsyncNotifier<List<SubjectModel>> {
  SubjectRepository get _repository => ref.read(subjectRepositoryProvider);
  final Map<String, List<SubjectModel>> _cache = {};

  @override
  Future<List<SubjectModel>> build() async {
    return [];
  }

  Future<void> loadSubjectsForClass(String classId, {bool refresh = false}) async {
    final cachedSubjects = _cache[classId];
    if (cachedSubjects != null && !refresh) {
      state = AsyncValue.data(cachedSubjects);
      return;
    }

    if (cachedSubjects == null) {
      state = const AsyncValue.loading();
    } else {
      state = AsyncValue.data(cachedSubjects);
    }

    state = await AsyncValue.guard(() async {
      final subjects = await _repository.getByClassId(classId);
      _cache[classId] = subjects;
      return subjects;
    });
  }

  Future<void> addSubject(String classId, String name) async {
    final newSubject = SubjectModel(classId: classId, name: name);
    final id = await _repository.insert(newSubject);
    final currentSubjects = _cache[classId] ?? const <SubjectModel>[];
    final nextDisplayOrder = currentSubjects.length;
    final updatedSubjects = [
      ...currentSubjects,
      newSubject.copyWith(id: id, displayOrder: nextDisplayOrder),
    ];

    _cache[classId] = updatedSubjects;
    state = AsyncValue.data(updatedSubjects);
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _repository.update(subject);
    final updatedSubjects =
        (_cache[subject.classId] ?? const <SubjectModel>[])
            .map((item) => item.id == subject.id ? subject : item)
            .toList(growable: false);
    _cache[subject.classId] = updatedSubjects;
    state = AsyncValue.data(updatedSubjects);
  }

  Future<void> deleteSubject(String id, String classId) async {
    await _repository.delete(id);
    final updatedSubjects =
        (_cache[classId] ?? const <SubjectModel>[])
            .where((subject) => subject.id != id)
            .toList(growable: false);
    _cache[classId] = updatedSubjects;
    state = AsyncValue.data(updatedSubjects);
  }

  Future<void> reorderSubjects(
    String classId,
    List<SubjectModel> orderedSubjects,
  ) async {
    final normalizedSubjects = orderedSubjects
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(displayOrder: entry.key),
        )
        .toList(growable: false);
    await _repository.reorderSubjects(
      classId: classId,
      orderedSubjects: normalizedSubjects,
    );
    _cache[classId] = normalizedSubjects;
    state = AsyncValue.data(normalizedSubjects);
  }

  Future<int> syncMissingAdviserSubjects(String classId) async {
    final existing = await _repository.getByClassId(classId);
    final existingNames = existing
        .map((subject) => subject.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    int inserted = 0;
    for (final subjectName in kAdviserDefaultSubjects) {
      if (!existingNames.contains(subjectName)) {
        await _repository.insert(
          SubjectModel(classId: classId, name: subjectName),
        );
        inserted++;
      }
    }

    await loadSubjectsForClass(classId, refresh: true);
    return inserted;
  }
}
