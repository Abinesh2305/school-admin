class Alumni {
  final int studentId;
  final String admissionNo;
  final String displayName;

  final int classId;
  final int sectionId;

  final String leavingDate;
  final String markedAt;
  final String reason;

  Alumni({
    required this.studentId,
    required this.admissionNo,
    required this.displayName,
    required this.classId,
    required this.sectionId,
    required this.leavingDate,
    required this.markedAt,
    required this.reason,
  });

  factory Alumni.fromJson(Map<String, dynamic> json) {
    return Alumni(
      studentId: json['studentId'],
      admissionNo: json['admissionNo'] ?? '',
      displayName: json['displayName'] ?? '',
      classId: json['classId'] ?? 0,
      sectionId: json['sectionId'] ?? 0,
      leavingDate: json['leavingDate'] ?? '',
      markedAt: json['markedAtUtc'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}
