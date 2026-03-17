import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_value_parser.dart';

class FolderModel {
  final String? id;
  final String teacherId;
  final String name;
  final String colorHex;
  final DateTime? createdAt;

  const FolderModel({
    this.id,
    required this.teacherId,
    required this.name,
    required this.colorHex,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'teacherId': teacherId,
      'name': name,
      'colorHex': colorHex,
    };

    if (id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }

    return map;
  }

  factory FolderModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return FolderModel(
      id: documentId ?? readNullableString(map['id']),
      teacherId: readString(map['teacherId']),
      name: readString(map['name']),
      colorHex: readString(map['colorHex']),
      createdAt: readDateTime(map['createdAt']),
    );
  }

  factory FolderModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return FolderModel.fromMap(
      document.data() ?? const {},
      documentId: document.id,
    );
  }

  FolderModel copyWith({
    String? id,
    String? teacherId,
    String? name,
    String? colorHex,
    DateTime? createdAt,
    bool clearCreatedAt = false,
  }) {
    return FolderModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
    );
  }
}
