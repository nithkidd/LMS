import 'firestore_value_parser.dart';

class TrellisClassModel {
  final String? id;
  final String teacherId;
  final String? folderId;
  final String name;
  final String academicYear;
  final double formativeWeight;
  final double summativeWeight;

  const TrellisClassModel({
    this.id,
    required this.teacherId,
    required this.folderId,
    required this.name,
    required this.academicYear,
    required this.formativeWeight,
    required this.summativeWeight,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'teacherId': teacherId,
      'folderId': folderId,
      'name': name,
      'academicYear': academicYear,
      'formativeWeight': formativeWeight,
      'summativeWeight': summativeWeight,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory TrellisClassModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return TrellisClassModel(
      id: documentId ?? readNullableString(map['id']),
      teacherId: readString(map['teacherId']),
      folderId: readNullableString(map['folderId']),
      name: readString(map['name']),
      academicYear: readString(map['academicYear']),
      formativeWeight: readDouble(map['formativeWeight']),
      summativeWeight: readDouble(map['summativeWeight']),
    );
  }

  TrellisClassModel copyWith({
    String? id,
    String? teacherId,
    Object? folderId = _sentinel,
    String? name,
    String? academicYear,
    double? formativeWeight,
    double? summativeWeight,
  }) {
    return TrellisClassModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      folderId: identical(folderId, _sentinel)
          ? this.folderId
          : folderId as String?,
      name: name ?? this.name,
      academicYear: academicYear ?? this.academicYear,
      formativeWeight: formativeWeight ?? this.formativeWeight,
      summativeWeight: summativeWeight ?? this.summativeWeight,
    );
  }
}

const Object _sentinel = Object();
