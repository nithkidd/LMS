class EligibleOrganization {
  const EligibleOrganization({required this.id, required this.name});

  final String id;
  final String name;

  factory EligibleOrganization.fromMap(String id, Map<String, dynamic> data) {
    final rawName = data['name']?.toString().trim();
    return EligibleOrganization(
      id: id,
      name: rawName == null || rawName.isEmpty ? id : rawName,
    );
  }
}
