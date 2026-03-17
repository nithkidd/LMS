import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/school_model.dart';
import '../repositories/school_repository.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository();
});

class SchoolNotifier extends AsyncNotifier<List<SchoolModel>> {
  @override
  FutureOr<List<SchoolModel>> build() async {
    return _loadSchools();
  }

  Future<List<SchoolModel>> _loadSchools() async {
    final repository = ref.read(schoolRepositoryProvider);
    return await repository.getAll();
  }

  Future<void> addSchool(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(schoolRepositoryProvider);
      final newSchool = SchoolModel(
        name: name,
        createdAt: DateTime.now().toIso8601String(),
      );
      await repository.insert(newSchool);
      return _loadSchools();
    });
  }

  Future<void> deleteSchool(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(schoolRepositoryProvider);
      await repository.delete(id);
      return _loadSchools();
    });
  }

  Future<void> updateSchool(String id, String newName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(schoolRepositoryProvider);
      final existing = await repository.getById(id);
      if (existing != null) {
        await repository.update(existing.copyWith(name: newName));
      }
      return _loadSchools();
    });
  }

  Future<void> reorderSchools(int oldIndex, int newIndex) async {
    final currentList = state.value;
    if (currentList == null) return;

    // Create a mutable copy
    final list = List<SchoolModel>.from(currentList);

    // Adjust newIndex for removal
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Move the item
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Update display order for all items
    final repository = ref.read(schoolRepositoryProvider);
    for (int i = 0; i < list.length; i++) {
      if (list[i].id != null) {
        await repository.updateDisplayOrder(list[i].id!, list.length - i);
      }
    }

    // Reload to get fresh data
    state = await AsyncValue.guard(() => _loadSchools());
  }
}

final schoolNotifierProvider =
    AsyncNotifierProvider<SchoolNotifier, List<SchoolModel>>(() {
      return SchoolNotifier();
    });
