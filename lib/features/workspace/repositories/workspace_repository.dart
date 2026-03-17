import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../classes/models/class_model.dart';
import '../../classes/repositories/class_repository.dart';
import '../../schools/models/school_model.dart';
import '../../schools/repositories/school_repository.dart';
import '../../subjects/models/subject_model.dart';
import '../../subjects/repositories/subject_repository.dart';
import '../models/workspace_folder.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository(
    classRepository: ClassRepository(),
    schoolRepository: SchoolRepository(),
    subjectRepository: SubjectRepository(),
  );
});

class WorkspaceRepository {
  WorkspaceRepository({
    required ClassRepository classRepository,
    required SchoolRepository schoolRepository,
    required SubjectRepository subjectRepository,
  }) : _classRepository = classRepository,
       _schoolRepository = schoolRepository,
       _subjectRepository = subjectRepository;

  static const String _workspaceFoldersKey = 'teacher_workspace_folders_v2';
  static const String _workspaceSchoolName = '__trellis_teacher_workspace__';

  static const List<String> _folderPalette = [
    '#D8EAE4',
    '#F6EAD2',
    '#E8E2F7',
    '#F7E2DB',
    '#DCEAF4',
  ];

  static const List<String> _adviserSubjects = [
    'ភាសាខ្មែរ',
    'សីលធម៌-ពលរដ្ឋវិជ្ជា',
    'ប្រវត្តិវិទ្យា',
    'ភូមិវិទ្យា',
    'គណិតវិទ្យា',
    'រូបវិទ្យា',
    'គីមីវិទ្យា',
    'ជីវវិទ្យា',
    'ផែនដីវិទ្យា',
    'ភាសាបរទេស',
    'បច្ចេកវិទ្យា',
    'គេហវិទ្យា',
    'អប់រំសិល្បៈ',
    'អប់រំកាយ កីឡា',
  ];

  final ClassRepository _classRepository;
  final SchoolRepository _schoolRepository;
  final SubjectRepository _subjectRepository;

  Future<List<ClassModel>> loadClasses() {
    return _classRepository.getAllClasses();
  }

  Future<List<WorkspaceFolder>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workspaceFoldersKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => WorkspaceFolder.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList()
      ..sort((a, b) {
        final aValue = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bValue = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return aValue.compareTo(bValue);
      });
  }

  Future<WorkspaceFolder> createFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Folder name cannot be empty.');
    }

    final folders = await loadFolders();
    final folder = WorkspaceFolder(
      id: 'folder_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      colorHex: _folderPalette[folders.length % _folderPalette.length],
      createdAt: DateTime.now(),
    );

    await _saveFolders([...folders, folder]);
    return folder;
  }

  Future<void> assignClassToFolder(String classId, String? folderId) async {
    final folders = await loadFolders();
    final normalized = folders
        .map(
          (folder) => folder.copyWith(
            classIds: folder.classIds
                .where((existingClassId) => existingClassId != classId)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    final updated = [
      for (final folder in normalized)
        if (folder.id == folderId)
          folder.copyWith(classIds: [...folder.classIds, classId])
        else
          folder,
    ];

    await _saveFolders(updated);
  }

  Future<void> createClass({
    required String name,
    required String academicYear,
    required bool isAdviser,
    required List<String> subjects,
  }) async {
    final trimmedName = name.trim();
    final trimmedYear = academicYear.trim();
    if (trimmedName.isEmpty || trimmedYear.isEmpty) {
      throw ArgumentError('Class name and academic year are required.');
    }

    final schoolId = await _ensureWorkspaceSchoolId();
    final classId = await _classRepository.insert(
      ClassModel(
        schoolId: schoolId,
        name: trimmedName,
        academicYear: trimmedYear,
        isAdviser: isAdviser,
      ),
    );

    final selectedSubjects = isAdviser
        ? _adviserSubjects
        : subjects
              .map((subject) => subject.trim())
              .where((subject) => subject.isNotEmpty)
              .toSet()
              .toList(growable: false);

    for (final subject in selectedSubjects) {
      await _subjectRepository.insert(
        SubjectModel(classId: classId, name: subject),
      );
    }
  }

  Future<String> _ensureWorkspaceSchoolId() async {
    final schools = await _schoolRepository.getAll();
    final existing = schools.firstWhereOrNull(
      (school) => school.name == _workspaceSchoolName,
    );
    if (existing?.id != null) {
      return existing!.id!;
    }

    return _schoolRepository.insert(
      SchoolModel(
        name: _workspaceSchoolName,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> _saveFolders(List<WorkspaceFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      folders.map((folder) => folder.toJson()).toList(growable: false),
    );
    await prefs.setString(_workspaceFoldersKey, raw);
  }
}

extension _IterableFirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) predicate) {
    for (final value in this) {
      if (predicate(value)) {
        return value;
      }
    }
    return null;
  }
}
