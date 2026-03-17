class StudentModel {
  final String? id;
  final String classId;
  final String name;
  final String? sex; // 'M' for male, 'F' for female
  final String? dateOfBirth; // ISO 8601 format (yyyy-MM-dd)
  final String? address;
  final String? remarks;

  StudentModel({
    this.id,
    required this.classId,
    required this.name,
    this.sex,
    this.dateOfBirth,
    this.address,
    this.remarks,
  });

  Map<String, dynamic> toDto() {
    return {
      'class_id': classId,
      'name': name,
      'sex': sex,
      'date_of_birth': dateOfBirth,
      'address': address,
      'remarks': remarks,
    };
  }

  factory StudentModel.fromDto(Map<dynamic, dynamic> map, String id) {
    return StudentModel(
      id: id,
      classId: map['class_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sex: map['sex']?.toString(),
      dateOfBirth: map['date_of_birth']?.toString(),
      address: map['address']?.toString(),
      remarks: map['remarks']?.toString(),
    );
  }

  StudentModel copyWith({
    String? id,
    String? classId,
    String? name,
    String? sex,
    String? dateOfBirth,
    String? address,
    String? remarks,
  }) {
    return StudentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      remarks: remarks ?? this.remarks,
    );
  }
}
