class Scholar {
  final int id;

  final String admissionNo;
  final String? photoUrl;
  final String firstName;
  final String? middleName;
  final String lastName;

  // From LIST / LOOKUP API
  final String? displayName;

  final int classId;
  final int sectionId;

  final String gender;
  final String? dob;
  // Academic / Admin
  final String admissionType;
  final String scholarCategory;
  final String scholarType;
  final String division;
  final String house;
  final String? doj;

  final String? medium;
  final String? batch;
  final String? motherTongue;

  final String fatherName;

  final String primaryMobile;
  final String? secondaryMobile;

  final Profile? profile;
  final Address? address;
  final Identifiers? identifiers;

  final int? status;

  Scholar({
    required this.id,
    required this.admissionNo,
    this.photoUrl,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.displayName,
    this.doj,

    required this.classId,
    required this.sectionId,

    required this.gender,
    this.dob,
    // Academic / Admin
    required this.admissionType,
    required this.scholarCategory,
    required this.scholarType,
    required this.division,
    required this.house,

    this.medium,
    this.batch,
    this.motherTongue,

    required this.fatherName,

    required this.primaryMobile,
    this.secondaryMobile,

    this.profile,
    this.address,
    this.identifiers,

    this.status,
  });

  /* ================= FULL NAME ================= */

  String get fullName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }

    return '$firstName ${middleName ?? ''} $lastName'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /* ================= FROM JSON ================= */

  static String? _normalize(dynamic value, List<String> options) {
    if (value == null) return null;

    final v = value.toString().trim().toLowerCase();

    for (final o in options) {
      if (o.toLowerCase() == v) return o;
    }

    return null;
  }

  factory Scholar.fromJson(Map<String, dynamic> json) {
    // Handle LIST API "name"
    final String? name = json['name'];

    String fName = '';
    String lName = '';

    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));

      if (parts.length == 1) {
        fName = parts[0];
      } else {
        fName = parts.first;
        lName = parts.sublist(1).join(' ');
      }
    }

    return Scholar(
      id: json['id'] ?? 0,

      admissionNo: json['admissionNo'] ?? '',
      photoUrl: json['photoUrl'],

      // DETAIL OR LIST API
      firstName: json['firstName'] ?? fName,
      middleName: json['middleName'],
      lastName: json['lastName'] ?? lName,

      displayName: json['name'],

      classId: json['classId'] ?? 0,
      sectionId: json['sectionId'] ?? 0,

      gender: json['gender'] ?? '',
      doj: json['doj'],

      admissionType:
          _normalize(json['admissionType'], ['New', 'Transfer']) ?? '',

      scholarCategory:
          _normalize(json['scholarCategory'], ['General', 'OBC', 'SC', 'ST']) ??
          '',

      scholarType:
          _normalize(json['scholarType'], ['Day Scholar', 'Hostel']) ?? '',

      division: _normalize(json['division'], ['Primary', 'Secondary']) ?? '',

      house: _normalize(json['house'], ['Red', 'Blue', 'Green']) ?? '',

      medium: json['medium'],
      batch: json['batch'],
      motherTongue: json['motherTongue'],

      fatherName: json['fatherName'] ?? '',

      primaryMobile: json['primaryMobile'] ?? '',
      secondaryMobile: json['secondaryMobile'],

      profile: json['profile'] != null
          ? Profile.fromJson(json['profile'])
          : null,

      address: json['address'] != null
          ? Address.fromJson(json['address'])
          : null,

      identifiers: json['identifiers'] != null
          ? Identifiers.fromJson(json['identifiers'])
          : null,

      status: json['status'],
    );
  }

  /* ================= TO JSON ================= */

  Map<String, dynamic> toJson() {
    return {
      'admissionNo': admissionNo,

      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,

      'classId': classId,
      'sectionId': sectionId,

      'gender': gender,
      'dob': dob,
      // Academic / Admin
      'admissionType': admissionType,
      'scholarCategory': scholarCategory,
      'scholarType': scholarType,
      'division': division,
      'house': house,
      'doj': doj,

      'medium': medium,
      'batch': batch,
      'motherTongue': motherTongue,

      'fatherName': fatherName,

      'primaryMobile': primaryMobile,
      'secondaryMobile': secondaryMobile,

      if (profile != null) 'profile': profile!.toJson(),
      if (address != null) 'address': address!.toJson(),
      if (identifiers != null) 'identifiers': identifiers!.toJson(),
    };
  }
}

/* ======================================================
                        PROFILE
   ====================================================== */

class Profile {
  final String motherName;
  final String? guardianName;
  final String? guardianRelation;

  final String? religion;

  final String community;

  final String? caste;
  final String bloodGroup;

  final bool appInstalled;

  Profile({
    required this.motherName,
    this.guardianName,
    this.guardianRelation,

    required this.religion,
    required this.community,

    this.caste,
    required this.bloodGroup,

    required this.appInstalled,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    print('RAW JSON → $json');

    return Profile(
      motherName: json['motherName'] ?? '',

      guardianName: json['guardianName'],
      guardianRelation: json['guardianRelation'],

      religion: json['religion'] ?? '',
      community: json['community'] ?? '',

      caste: json['caste'],
      bloodGroup: json['bloodGroup'] ?? '',

      appInstalled: json['appInstalled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'motherName': motherName,
      'guardianName': guardianName,
      'guardianRelation': guardianRelation,

      'religion': religion,
      'community': community,

      'caste': caste,
      'bloodGroup': bloodGroup,

      'appInstalled': appInstalled,
    };
  }
}

/* ======================================================
                        ADDRESS
   ====================================================== */

class Address {
  final String commAddressLine1;
  final String? commAddressLine2;
  final String commCity;
  final String commPincode;

  final String permAddressLine1;
  final String? permAddressLine2;
  final String permCity;
  final String permPincode;

  Address({
    required this.commAddressLine1,
    this.commAddressLine2,

    required this.commCity,
    required this.commPincode,

    required this.permAddressLine1,
    this.permAddressLine2,

    required this.permCity,
    required this.permPincode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      commAddressLine1: json['commAddressLine1'] ?? '',
      commAddressLine2: json['commAddressLine2'],

      commCity: json['commCity'] ?? '',
      commPincode: json['commPincode'] ?? '',

      permAddressLine1: json['permAddressLine1'] ?? '',
      permAddressLine2: json['permAddressLine2'],

      permCity: json['permCity'] ?? '',
      permPincode: json['permPincode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commAddressLine1': commAddressLine1,
      'commAddressLine2': commAddressLine2,

      'commCity': commCity,
      'commPincode': commPincode,

      'permAddressLine1': permAddressLine1,
      'permAddressLine2': permAddressLine2,

      'permCity': permCity,
      'permPincode': permPincode,
    };
  }
}

/* ======================================================
                      IDENTIFIERS
   ====================================================== */

class Identifiers {
  final String? aadhaar;

  final String? emis;
  final String? apar;
  final String? udis;

  Identifiers({required this.aadhaar, this.emis, this.apar, this.udis});

  factory Identifiers.fromJson(Map<String, dynamic> json) {
    return Identifiers(
      aadhaar: json['aadhaar'] ?? '',

      emis: json['emis'],
      apar: json['apar'],
      udis: json['udis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'aadhaar': aadhaar, 'emis': emis, 'apar': apar, 'udis': udis};
  }
}
