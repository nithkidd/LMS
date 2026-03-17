import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../classes/models/class_model.dart';
import '../models/workspace_folder.dart';
import '../repositories/workspace_repository.dart';

final workspaceNotifierProvider =
    AsyncNotifierProvider<WorkspaceNotifier, WorkspaceState>(
      WorkspaceNotifier.new,
    );

class WorkspaceState {
  WorkspaceState({
    required this.classes,
    required this.folders,
    this.selectedFolderId,
  }) : totalStudents = classes.fold<int>(
         0,
         (sum, classModel) => sum + classModel.totalStudents,
       ),
       folderByClassId = _buildFolderByClassId(folders),
       folderById = {for (final folder in folders) folder.id: folder};

  final List<ClassModel> classes;
  final List<WorkspaceFolder> folders;
  final String? selectedFolderId;
  final int totalStudents;
  final Map<String, WorkspaceFolder> folderByClassId;
  final Map<String, WorkspaceFolder> folderById;

  List<ClassModel> get unassignedClasses {
    final assignedIds = folderByClassId.keys.toSet();
    return classes
        .where((classModel) => !assignedIds.contains(classModel.id))
        .toList(growable: false);
  }

  WorkspaceFolder? get selectedFolder {
    if (selectedFolderId == null) {
      return null;
    }
    return folderById[selectedFolderId];
  }

  WorkspaceFolder? folderForClass(String? classId) {
    if (classId == null) {
      return null;
    }
    return folderByClassId[classId];
  }

  List<ClassModel> classesForFolder(String folderId) {
    final classIds = folderById[folderId]?.classIds.toSet() ?? const <String>{};

    return classes
        .where((classModel) => classIds.contains(classModel.id))
        .toList(growable: false);
  }

  WorkspaceState copyWith({
    List<ClassModel>? classes,
    List<WorkspaceFolder>? folders,
    Object? selectedFolderId = _sentinel,
  }) {
    return WorkspaceState(
      classes: classes ?? this.classes,
      folders: folders ?? this.folders,
      selectedFolderId: identical(selectedFolderId, _sentinel)
          ? this.selectedFolderId
          : selectedFolderId as String?,
    );
  }
}

class WorkspaceNotifier extends AsyncNotifier<WorkspaceState> {
  @override
  FutureOr<WorkspaceState> build() {
    return _loadState();
  }

  Future<void> refresh() async {
    final selectedFolderId = state.asData?.value.selectedFolderId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadState(selectedFolderId));
  }

  void selectFolder(String? folderId) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    state = AsyncValue.data(current.copyWith(selectedFolderId: folderId));
  }

  Future<void> createFolder(String name) async {
    final repository = ref.read(workspaceRepositoryProvider);
    final folder = await repository.createFolder(name);
    final current = state.asData?.value;
    if (current == null) {
      await refresh();
      return;
    }

    state = AsyncValue.data(
      current.copyWith(folders: [...current.folders, folder]),
    );
  }

  Future<void> createClass({
    required String name,
    required String academicYear,
    required bool isAdviser,
    required List<String> subjects,
  }) async {
    final repository = ref.read(workspaceRepositoryProvider);
    await repository.createClass(
      name: name,
      academicYear: academicYear,
      isAdviser: isAdviser,
      subjects: subjects,
    );
    await refresh();
  }

  Future<void> assignClassToFolder(String classId, String? folderId) async {
    final repository = ref.read(workspaceRepositoryProvider);
    await repository.assignClassToFolder(classId, folderId);
    final current = state.asData?.value;
    if (current == null) {
      final selectedFolderId = state.asData?.value.selectedFolderId;
      state = await AsyncValue.guard(() => _loadState(selectedFolderId));
      return;
    }

    final updatedFolders = current.folders
        .map(
          (folder) => folder.copyWith(
            classIds: [
              for (final existingId in folder.classIds)
                if (existingId != classId) existingId,
              if (folder.id == folderId) classId,
            ],
          ),
        )
        .toList(growable: false);

    state = AsyncValue.data(current.copyWith(folders: updatedFolders));
  }

  Future<WorkspaceState> _loadState([String? selectedFolderId]) async {
    final repository = ref.read(workspaceRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repository.loadClasses(),
      repository.loadFolders(),
    ]);
    final classes = results[0] as List<ClassModel>;
    final folders = results[1] as List<WorkspaceFolder>;

    final validClassIds = classes
        .map((classModel) => classModel.id)
        .whereType<String>()
        .toSet();
    final normalizedFolders = folders
        .map(
          (folder) => folder.copyWith(
            classIds: folder.classIds
                .where((classId) => validClassIds.contains(classId))
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    final hasSelectedFolder = normalizedFolders.any(
      (folder) => folder.id == selectedFolderId,
    );

    return WorkspaceState(
      classes: classes,
      folders: normalizedFolders,
      selectedFolderId: hasSelectedFolder ? selectedFolderId : null,
    );
  }
}

const Object _sentinel = Object();

Map<String, WorkspaceFolder> _buildFolderByClassId(List<WorkspaceFolder> folders) {
  final folderByClassId = <String, WorkspaceFolder>{};
  for (final folder in folders) {
    for (final classId in folder.classIds) {
      folderByClassId[classId] = folder;
    }
  }
  return folderByClassId;
}
