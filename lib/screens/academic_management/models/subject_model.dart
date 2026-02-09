class Subject {
  final int id;
  final String name;
  final String code;
  final int sortOrder;
  final bool isActive;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.sortOrder,
    required this.isActive,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "code": code,
      "sortOrder": sortOrder,
    };
  }
}
