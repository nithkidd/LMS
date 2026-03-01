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
      final newSchool = SchoolModel(name: name);
      await repository.insert(newSchool);
      return _loadSchools();
    });
  }

  Future<void> deleteSchool(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(schoolRepositoryProvider);
      await repository.delete(id);
      return _loadSchools();
    });
  }
}

final schoolNotifierProvider = AsyncNotifierProvider<SchoolNotifier, List<SchoolModel>>(() {
  return SchoolNotifier();
});
