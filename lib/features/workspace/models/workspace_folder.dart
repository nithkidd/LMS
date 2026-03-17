class WorkspaceFolder {
  const WorkspaceFolder({
    required this.id,
    required this.name,
    required this.colorHex,
    this.classIds = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String colorHex;
  final List<String> classIds;
  final DateTime? createdAt;

  int get classCount => classIds.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'classIds': classIds,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory WorkspaceFolder.fromJson(Map<String, dynamic> json) {
    return WorkspaceFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      colorHex: json['colorHex']?.toString() ?? '#D8EAE4',
      classIds: (json['classIds'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  WorkspaceFolder copyWith({
    String? id,
    String? name,
    String? colorHex,
    List<String>? classIds,
    DateTime? createdAt,
    bool clearCreatedAt = false,
  }) {
    return WorkspaceFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      classIds: classIds ?? this.classIds,
      createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is WorkspaceFolder &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex &&
        _listEquals(other.classIds, classIds);
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, Object.hashAll(classIds));

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
