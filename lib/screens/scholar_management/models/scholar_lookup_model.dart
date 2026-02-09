class ScholarLookup {
  final int id;
  final String admissionNo;
  final String name;
  final int classId;
  final int sectionId;

  ScholarLookup({
    required this.id,
    required this.admissionNo,
    required this.name,
    required this.classId,
    required this.sectionId,
  });

  factory ScholarLookup.fromJson(Map<String, dynamic> json) {
    return ScholarLookup(
      id: json['id'],
      admissionNo: json['admissionNo'],
      name: json['name'],
      classId: json['classId'],
      sectionId: json['sectionId'],
    );
  }
}
