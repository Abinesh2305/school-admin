class Staff {
  final int id;

  final String fullName;
  final String employeeCode;
  final String phone;
  final String email;

  //  Extra Fields
  final String? altMobile;

  final String? roleName;   // Admin / Teacher / 
  final String? roleKey;    // admin / teacher / 

  final int? academicYearId;
  final String? academicYearName;

  final bool isActive;
  final String photoUrl;

  Staff({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    required this.phone,
    required this.email,

    this.altMobile,

    this.roleName,
    this.roleKey,

    this.academicYearId,
    this.academicYearName,

    required this.isActive,
    required this.photoUrl,
  });

  // ================= FROM JSON =================

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],

      fullName: json['fullName'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',

      altMobile: json['altMobile'],

      roleName: json['roleName'],
      roleKey: json['roleKey'],

      academicYearId: json['academicYearId'],
      academicYearName: json['academicYearName'],

      isActive: json['isActive'] ?? true,

      photoUrl: json['photoUrl'] ??
          'https://via.placeholder.com/150',
    );
  }
}
