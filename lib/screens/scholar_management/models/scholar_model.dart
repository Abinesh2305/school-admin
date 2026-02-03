import 'dart:io';

class Scholar {
  String admNo;
  String name;
  String className;
  String section;
  String gender;
  String mobile;
  String fatherName;

  // ✅ ADD THIS
  File? studentImage;

  Scholar({
    required this.admNo,
    required this.name,
    required this.className,
    required this.section,
    required this.gender,
    required this.mobile,
    required this.fatherName,
    this.studentImage,
  });
}
