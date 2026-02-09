class Preadmission {
  final int id;
  final String applicationNo;
  final String status;

  final String displayName;

  final String firstName;
  final String? middleName;
  final String lastName;

  final String primaryMobile;
  final String? secondaryMobile;
  final String? email;

  final String dob;
  final String gender;

  final String fatherName;
  final String motherName;

  final int desiredClassId;
  final int desiredSectionId;

  final String? notes;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final DateTime? convertedAt;

  final int? convertedStudentId;
  final String? decisionReason;

  Preadmission({
    required this.id,
    required this.applicationNo,
    required this.status,

    required this.displayName,

    required this.firstName,
    this.middleName,
    required this.lastName,

    required this.primaryMobile,
    this.secondaryMobile,
    this.email,

    required this.dob,
    required this.gender,

    required this.fatherName,
    required this.motherName,

    required this.desiredClassId,
    required this.desiredSectionId,

    this.notes,

    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.decidedAt,
    this.convertedAt,

    this.convertedStudentId,
    this.decisionReason,
  });

  /* ================= FROM JSON ================= */

  factory Preadmission.fromJson(Map<String, dynamic> json) {
    return Preadmission(
      id: json['id'] ?? 0,
      applicationNo: json['applicationNo'] ?? '',
      status: json['status'] ?? '',

      displayName: json['displayName'] ?? '',

      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',

      primaryMobile: json['primaryMobile'] ?? '',
      secondaryMobile: json['secondaryMobile'],
      email: json['email'],

      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',

      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'] ?? '',

      desiredClassId: json['desiredClassId'] ?? 0,
      desiredSectionId: json['desiredSectionId'] ?? 0,

      notes: json['notes'],

      createdAt: _parseDate(json['createdAtUtc']),
      updatedAt: _parseDate(json['updatedAtUtc']),
      submittedAt: _parseDate(json['submittedAtUtc']),
      decidedAt: _parseDate(json['decidedAtUtc']),
      convertedAt: _parseDate(json['convertedAtUtc']),

      convertedStudentId: json['convertedStudentId'],
      decisionReason: json['decisionReason'],
    );
  }

  /* ================= TO JSON (CREATE) ================= */

  Map<String, dynamic> toCreateJson() {
    return {
      "firstName": firstName,
      "middleName": middleName,
      "lastName": lastName,

      "primaryMobile": primaryMobile,
      "secondaryMobile": secondaryMobile,
      "email": email,

      "desiredClassId": desiredClassId,
      "desiredSectionId": desiredSectionId,

      "dob": dob,
      "gender": gender,

      "fatherName": fatherName,
      "motherName": motherName,

      "notes": notes,
    };
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
}
