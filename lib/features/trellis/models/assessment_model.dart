import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_value_parser.dart';

enum AssessmentType {
  formative('formative'),
  summative('summative');

  final String value;

  const AssessmentType(this.value);

  static AssessmentType fromValue(Object? rawValue) {
    final normalized = rawValue?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'formative':
        return AssessmentType.formative;
      case 'summative':
        return AssessmentType.summative;
      default:
        throw ArgumentError.value(
          rawValue,
          'rawValue',
          'Unsupported assessment type',
        );
    }
  }
}

class AssessmentModel {
  final String? id;
  final String classId;
  final String title;
  final DateTime? date;
  final AssessmentType type;
  final int maxScore;

  const AssessmentModel({
    this.id,
    required this.classId,
    required this.title,
    required this.date,
    required this.type,
    required this.maxScore,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'classId': classId,
      'title': title,
      'type': type.value,
      'maxScore': maxScore,
    };

    if (id != null) {
      map['id'] = id;
    }
    if (date != null) {
      map['date'] = Timestamp.fromDate(date!);
    }

    return map;
  }

  factory AssessmentModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return AssessmentModel(
      id: documentId ?? readNullableString(map['id']),
      classId: readString(map['classId']),
      title: readString(map['title']),
      date: readDateTime(map['date']),
      type: AssessmentType.fromValue(map['type']),
      maxScore: readInt(map['maxScore']),
    );
  }

  factory AssessmentModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return AssessmentModel.fromMap(
      document.data() ?? const {},
      documentId: document.id,
    );
  }

  AssessmentModel copyWith({
    String? id,
    String? classId,
    String? title,
    DateTime? date,
    bool clearDate = false,
    AssessmentType? type,
    int? maxScore,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      date: clearDate ? null : (date ?? this.date),
      type: type ?? this.type,
      maxScore: maxScore ?? this.maxScore,
    );
  }
}
