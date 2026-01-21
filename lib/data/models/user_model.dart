/// User model representing authenticated user data
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? apiToken;
  final String language;
  final int isAppInstalled;
  final int schoolCollegeId;
  final String? mainRefNo;
  final String? profileImage;
  final UserDetailsModel? userDetails;
  final List<dynamic>? groups;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.apiToken,
    this.language = 'en',
    this.isAppInstalled = 1,
    required this.schoolCollegeId,
    this.mainRefNo,
    this.profileImage,
    this.userDetails,
    this.groups,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      apiToken: json['api_token'] as String?,
      language: json['language'] as String? ?? 'en',
      isAppInstalled: json['is_app_installed'] as int? ?? 1,
      schoolCollegeId: json['school_college_id'] as int? ?? 
                      int.tryParse(json['school_college_id'].toString()) ?? 0,
      mainRefNo: json['main_ref_no'] as String?,
      profileImage: json['is_profile_image'] as String?,
      userDetails: json['userdetails'] != null
          ? UserDetailsModel.fromJson(
              Map<String, dynamic>.from(json['userdetails']))
          : null,
      groups: json['groups'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'api_token': apiToken,
      'language': language,
      'is_app_installed': isAppInstalled,
      'school_college_id': schoolCollegeId,
      'main_ref_no': mainRefNo,
      'is_profile_image': profileImage,
      'userdetails': userDetails?.toJson(),
      'groups': groups,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? apiToken,
    String? language,
    int? isAppInstalled,
    int? schoolCollegeId,
    String? mainRefNo,
    String? profileImage,
    UserDetailsModel? userDetails,
    List<dynamic>? groups,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      apiToken: apiToken ?? this.apiToken,
      language: language ?? this.language,
      isAppInstalled: isAppInstalled ?? this.isAppInstalled,
      schoolCollegeId: schoolCollegeId ?? this.schoolCollegeId,
      mainRefNo: mainRefNo ?? this.mainRefNo,
      profileImage: profileImage ?? this.profileImage,
      userDetails: userDetails ?? this.userDetails,
      groups: groups ?? this.groups,
    );
  }
}

/// User details model
class UserDetailsModel {
  final String? className;
  final String? sectionName;
  final int? classId;
  final int? sectionId;
  final int? schoolId;
  final String? admissionNo;
  final String? rollNo;

  UserDetailsModel({
    this.className,
    this.sectionName,
    this.classId,
    this.sectionId,
    this.schoolId,
    this.admissionNo,
    this.rollNo,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      className: json['is_class_name'] as String?,
      sectionName: json['is_section_name'] as String?,
      classId: json['is_class_id'] as int?,
      sectionId: json['is_section_id'] ?? 
                 json['section_id'] as int?,
      schoolId: json['school_id'] as int? ?? 
                json['school_college_id'] as int?,
      admissionNo: json['admission_no'] as String?,
      rollNo: json['roll_no'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_class_name': className,
      'is_section_name': sectionName,
      'is_class_id': classId,
      'is_section_id': sectionId,
      'school_id': schoolId,
      'admission_no': admissionNo,
      'roll_no': rollNo,
    };
  }
}

