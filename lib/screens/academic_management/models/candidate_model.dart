class Candidate {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final int stage;
  final String? notes;
  final bool isActive;

  Candidate({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.stage,
    this.notes,
    required this.isActive,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      stage: json['stage'] ?? 0,
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
    );
  }
}
