import 'package:ClasteqSMS/screens/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'models/scholar_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'scholar_service.dart';
import 'package:intl/intl.dart';

class AddEditScholarScreen extends StatefulWidget {
  final Scholar? scholar;

  const AddEditScholarScreen({super.key, this.scholar});

  @override
  State<AddEditScholarScreen> createState() => _AddEditScholarScreenState();
}

class _AddEditScholarScreenState extends State<AddEditScholarScreen> {
  String? _nullIfEmpty(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  bool detailed = false;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();
  File? _studentImage;
  List<int> classList = [];
  List<int> sectionList = [];

  // Basic
  final firstNameCtrl = TextEditingController();
  final middleNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final admNoCtrl = TextEditingController();
  final joiningGradeCtrl = TextEditingController();

  // Contacts
  final fatherCtrl = TextEditingController();
  final motherCtrl = TextEditingController();
  final primaryMobileCtrl = TextEditingController();
  final secondaryMobileCtrl = TextEditingController();
  final fatherEmailCtrl = TextEditingController();
  final motherEmailCtrl = TextEditingController();

  // Academic / Admin
  String? admissionType;
  String? scholarCategory;
  String? scholarType;
  String? division;
  String? house;
  DateTime? doj;
  String? medium;
  String? batch;
  String? motherTongue;

  // IDs
  final emisCtrl = TextEditingController();
  final udiseCtrl = TextEditingController();
  final apaarCtrl = TextEditingController();
  final rollNoCtrl = TextEditingController();
  final examRegCtrl = TextEditingController();
  final aadhaarCtrl = TextEditingController();

  // ===== Socio =====
  String community = '';
  final casteCtrl = TextEditingController();
  final religionCtrl = TextEditingController();
  final fatherOccupationCtrl = TextEditingController();
  final motherOccupationCtrl = TextEditingController();
  final annualIncomeCtrl = TextEditingController();
  String bloodGroup = '';
  final nationalityCtrl = TextEditingController();

  // ===== Transport =====
  String transportMode = '';
  final guardianNameCtrl = TextEditingController();
  final guardianMobileCtrl = TextEditingController();

  // ===== Address =====
  final communicationAddressCtrl = TextEditingController();
  final permanentAddressCtrl = TextEditingController();

  // ===== Misc =====
  final regionalNameCtrl = TextEditingController();
  final idMark1Ctrl = TextEditingController();
  final idMark2Ctrl = TextEditingController();

  String gender = '';
  int? selectedClassId;
  int? selectedSectionId;

  @override
  void initState() {
    super.initState();

    _loadDropdowns();
    if (widget.scholar != null) {
      _loadScholarDetails(widget.scholar!.id);
    }
  }

  Future<void> _uploadPhotoIfNeeded() async {
    if (_studentImage == null) return;

    final admissionNo = admNoCtrl.text.trim();

    if (admissionNo.isEmpty) {
      throw Exception('Admission No required for photo upload');
    }

    final service = ScholarService();

    await service.uploadScholarPhoto(
      file: _studentImage!,
      admissionNo: admissionNo,
    );
  }

  String? _matchDropdown(String? apiValue, List<String> items) {
    if (apiValue == null) return null;

    final v = apiValue.trim().toLowerCase();

    for (final item in items) {
      if (item.toLowerCase() == v) {
        return item; // exact dropdown value
      }
    }

    return null;
  }

  Future<void> _loadScholarDetails(int id) async {
    try {
      final service = ScholarService();

      final s = await service.getById(id);
      print('API admissionType = ${s.admissionType}');
      print('API category = ${s.scholarCategory}');
      print('API division = ${s.division}');
      print('API house = ${s.house}');

      setState(() {
        // Basic
        firstNameCtrl.text = s.firstName;
        middleNameCtrl.text = s.middleName ?? '';
        lastNameCtrl.text = s.lastName;

        admNoCtrl.text = s.admissionNo;

        doj = _parseDate(s.dob);
        gender = s.gender;

        selectedClassId = s.classId;
        selectedSectionId = s.sectionId;

        admissionType = _matchDropdown(s.admissionType, ['New', 'Transfer']);

        scholarCategory = _matchDropdown(s.scholarCategory, [
          'General',
          'OBC',
          'SC',
          'ST',
        ]);

        scholarType = _matchDropdown(s.scholarType, ['Day Scholar', 'Hostel']);

        division = _matchDropdown(s.division, ['Primary', 'Secondary']);

        house = _matchDropdown(s.house, ['Red', 'Blue', 'Green']);

        medium = _matchDropdown(s.medium, ['English', 'Tamil']);
        batch = _matchDropdown(s.batch, ['2023-24', '2024-25']);
        motherTongue = _matchDropdown(s.motherTongue, ['Tamil', 'English']);
        fatherCtrl.text = s.fatherName;
        motherCtrl.text = s.profile?.motherName ?? '';

        primaryMobileCtrl.text = s.primaryMobile;
        secondaryMobileCtrl.text = s.secondaryMobile ?? '';

        // Socio
        community = s.profile?.community ?? '';
        bloodGroup = s.profile?.bloodGroup ?? '';
        religionCtrl.text = s.profile?.religion ?? '';
        casteCtrl.text = s.profile?.caste ?? '';

        // Address
        communicationAddressCtrl.text = s.address?.commAddressLine1 ?? '';

        permanentAddressCtrl.text = s.address?.permAddressLine1 ?? '';

        // IDs
        aadhaarCtrl.text = s.identifiers?.aadhaar ?? '';
        emisCtrl.text = s.identifiers?.emis ?? '';
        apaarCtrl.text = s.identifiers?.apar ?? '';
        udiseCtrl.text = s.identifiers?.udis ?? '';
      });
    } catch (e) {
      debugPrint('Load detail error: $e');
    }
  }

  Future<void> _loadDropdowns() async {
    try {
      final service = ScholarService();

      // Example: Use lookup API or class API
      final list = await service.getAll();

      // Extract unique class IDs
      final classes = list.map((e) => e.classId).toSet().toList();

      // Extract unique section IDs
      final sections = list.map((e) => e.sectionId).toSet().toList();

      setState(() {
        classList = classes;
        sectionList = sections;
      });
    } catch (e) {
      debugPrint('Dropdown load error: $e');
    }
  }

  Future<void> _openCameraAndCrop() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );

    if (image == null) return;

    _openCropScreen(File(image.path));
  }

  Future<void> _openGalleryAndCrop() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    _openCropScreen(File(image.path));
  }

  Future<void> _openCropScreen(File imageFile) async {
    final File? croppedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => CropYourImageScreen(imageFile: imageFile),
      ),
    );

    if (croppedFile != null) {
      setState(() {
        _studentImage = croppedFile;
      });
    }
  }

  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _openCameraAndCrop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _openGalleryAndCrop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickStudentImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _studentImage = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    _scrollCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    admNoCtrl.dispose();
    joiningGradeCtrl.dispose();

    fatherCtrl.dispose();
    motherCtrl.dispose();
    primaryMobileCtrl.dispose();
    secondaryMobileCtrl.dispose();
    fatherEmailCtrl.dispose();
    motherEmailCtrl.dispose();

    emisCtrl.dispose();
    udiseCtrl.dispose();
    apaarCtrl.dispose();
    rollNoCtrl.dispose();
    examRegCtrl.dispose();
    aadhaarCtrl.dispose();

    casteCtrl.dispose();
    religionCtrl.dispose();
    fatherOccupationCtrl.dispose();
    motherOccupationCtrl.dispose();
    annualIncomeCtrl.dispose();
    nationalityCtrl.dispose();

    guardianNameCtrl.dispose();
    guardianMobileCtrl.dispose();

    communicationAddressCtrl.dispose();
    permanentAddressCtrl.dispose();

    regionalNameCtrl.dispose();
    idMark1Ctrl.dispose();
    idMark2Ctrl.dispose();

    super.dispose();
  }

  DateTime? _parseDate(String? date) {
    if (date == null || date.isEmpty) return null;

    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688), // TEAL
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Scholar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          const Text('Mandatory', style: TextStyle(fontSize: 12)),
          Switch(
            value: detailed,
            onChanged: (v) => setState(() => detailed = v),
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            activeTrackColor: Colors.white24,
            inactiveTrackColor: Colors.white24,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const Text('Detailed', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Basic'),

              _studentImageBar(),

              const SizedBox(height: 20),

              _responsiveForm([
                _text(firstNameCtrl, 'First Name*'),
                _text(middleNameCtrl, 'Middle Name'),
                _text(lastNameCtrl, 'Last Name'),
              ]),

              const SizedBox(height: 12),

              _responsiveForm([
                _text(admNoCtrl, 'Admission No*'),
                _dropdown('Gender*', gender, [
                  'Male',
                  'Female',
                ], (v) => setState(() => gender = v)),
                _intDropdown(
                  'Class*',
                  selectedClassId,
                  classList,
                  (v) => setState(() => selectedClassId = v),
                ),

                _intDropdown(
                  'Section*',
                  selectedSectionId,
                  sectionList,
                  (v) => setState(() => selectedSectionId = v),
                ),

                _text(joiningGradeCtrl, 'Joining Grade'),
              ]),

              const SizedBox(height: 24),
              _sectionTitle('Contacts'),

              _responsiveForm([
                _text(fatherCtrl, 'Father Name*'),
                _text(motherCtrl, 'Mother Name*'),
                _text(
                  primaryMobileCtrl,
                  'Primary Mobile*',
                  keyboard: TextInputType.phone,
                ),

                if (detailed) ...[
                  _text(
                    secondaryMobileCtrl,
                    'Secondary Mobile',
                    keyboard: TextInputType.phone,
                  ),
                  _text(
                    fatherEmailCtrl,
                    'Father Email',
                    keyboard: TextInputType.emailAddress,
                  ),
                  _text(
                    motherEmailCtrl,
                    'Mother Email',
                    keyboard: TextInputType.emailAddress,
                  ),
                ],
              ]),

              const SizedBox(height: 24),
              _sectionTitle('Academic / Admin'),

              _responsiveForm([
                _dropdown(
                  'Admission Type*',
                  admissionType,
                  ['New', 'Transfer'],
                  (v) => setState(() => admissionType = v),
                ),

                _dropdown(
                  'Scholar Category*',
                  scholarCategory,
                  ['General', 'OBC', 'SC', 'ST'],
                  (v) => setState(() => scholarCategory = v),
                ),

                _dropdown('Scholar Type*', scholarType, [
                  'Day Scholar',
                  'Hostel',
                ], (v) => setState(() => scholarType = v)),

                _dropdown('Division*', division, [
                  'Primary',
                  'Secondary',
                ], (v) => setState(() => division = v)),

                _dropdown('House*', house, [
                  'Red',
                  'Blue',
                  'Green',
                ], (v) => setState(() => house = v)),

                _dateField('DOJ*', doj, (d) => setState(() => doj = d)),
              ]),
              if (detailed) ...[
                const SizedBox(height: 16),

                _responsiveForm([
                  _dropdown('Medium', medium, [
                    'English',
                    'Tamil',
                  ], (v) => setState(() => medium = v)),

                  _dropdown('Batch', batch, [
                    '2023-24',
                    '2024-25',
                  ], (v) => setState(() => batch = v)),

                  _dropdown(
                    'Mother Tongue',
                    motherTongue,
                    ['Tamil', 'English'],
                    (v) => setState(() => motherTongue = v),
                  ),
                ]),

                const SizedBox(height: 24),
                _sectionTitle('IDs'),

                _responsiveForm([
                  _text(emisCtrl, 'EMIS'),
                  _text(udiseCtrl, 'UDISE'),
                  _text(apaarCtrl, 'APAAR'),
                  _text(rollNoCtrl, 'Roll Number'),
                  _text(examRegCtrl, 'Exam Register Number'),
                  _text(aadhaarCtrl, 'Aadhaar'),
                ]),
              ],
              // ===================== DETAILED ONLY =====================
              if (detailed) ...[
                const SizedBox(height: 32),

                _sectionTitle('Socio'),
                _responsiveForm([
                  _dropdown('Community', community, [
                    'OC',
                    'BC',
                    'MBC',
                    'SC',
                    'ST',
                  ], (v) => setState(() => community = v)),
                  _text(casteCtrl, 'Caste'),
                  _text(religionCtrl, 'Religion'),
                  _text(fatherOccupationCtrl, 'Father occupation'),
                  _text(motherOccupationCtrl, 'Mother occupation'),
                  _text(
                    annualIncomeCtrl,
                    'Annual Income',
                    keyboard: TextInputType.number,
                  ),
                  _dropdown('Blood Group', bloodGroup, [
                    'A+',
                    'A-',
                    'B+',
                    'B-',
                    'O+',
                    'O-',
                    'AB+',
                    'AB-',
                  ], (v) => setState(() => bloodGroup = v)),
                  _text(nationalityCtrl, 'Nationality'),
                ]),

                const SizedBox(height: 24),
                _sectionTitle('Transport'),
                _responsiveForm([
                  _dropdown(
                    'Transport mode',
                    transportMode,
                    ['Bus', 'Van', 'Own', 'None'],
                    (v) => setState(() => transportMode = v),
                  ),
                  _text(guardianNameCtrl, 'Guardian name'),
                  _text(
                    guardianMobileCtrl,
                    'Guardian mobile',
                    keyboard: TextInputType.phone,
                  ),
                ]),

                const SizedBox(height: 24),
                _sectionTitle('Addresses'),
                _responsiveForm([
                  _text(communicationAddressCtrl, 'Communication address'),
                  _text(permanentAddressCtrl, 'Permanent address'),
                ]),

                const SizedBox(height: 24),
                _sectionTitle('Misc'),
                _responsiveForm([
                  _text(regionalNameCtrl, 'Name (regional language)'),
                  _text(idMark1Ctrl, 'Identification mark 1'),
                  _text(idMark2Ctrl, 'Identification mark 2'),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /* ================= HELPERS ================= */
  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1990),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          errorText: label.contains('*') && value == null ? 'Required' : null,
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value.day}-${value.month}-${value.year}',
          style: TextStyle(color: value == null ? Colors.grey : Colors.black),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _responsiveForm(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // 📱 MOBILE
          return Column(
            children: children
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: e,
                  ),
                )
                .toList(),
          );
        }

        // 💻 TABLET / DESKTOP
        final columns = constraints.maxWidth > 900 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }

  Widget _text(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: label.contains('*')
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,

      validator: label.contains('*')
          ? (v) => v == null ? 'Required' : null
          : null,

      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),

      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),

      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _intDropdown(
    String label,
    int? value,
    List<int> items,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: items.contains(value) ? value : null,

      validator: label.contains('*')
          ? (v) => v == null ? 'Required' : null
          : null,

      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),

      items: items.map((e) {
        return DropdownMenuItem<int>(
          value: e,
          child: Text(e.toString()), // show number
        );
      }).toList(),

      onChanged: onChanged,
    );
  }

  Widget _studentImageBar() {
    const teal = Color(0xFF009688);

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // 👤 Profile image
          InkWell(
            onTap: _showImageSourcePicker,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: _studentImage != null
                  ? FileImage(_studentImage!)
                  : null,
              child: _studentImage == null
                  ? const Icon(Icons.person, size: 55, color: Colors.white)
                  : null,
            ),
          ),

          // 📷 Camera icon (same action)
          InkWell(
            onTap: _showImageSourcePicker,
            child: Container(
              margin: const EdgeInsets.only(right: 4, bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      return;
    }

    if (gender.isEmpty ||
        admissionType == null ||
        scholarCategory == null ||
        scholarType == null ||
        division == null ||
        house == null ||
        doj == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory fields')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final service = ScholarService();

      final scholar = Scholar(
        id: widget.scholar?.id ?? 0,

        admissionNo: admNoCtrl.text.trim(),

        firstName: firstNameCtrl.text.trim(),
        middleName: middleNameCtrl.text.trim().isEmpty
            ? null
            : middleNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),

        classId: selectedClassId!,
        sectionId: selectedSectionId!,

        gender: gender,
        dob: doj == null ? null : DateFormat('yyyy-MM-dd').format(doj!),
        admissionType: admissionType!,
        scholarCategory: scholarCategory!,
        scholarType: scholarType!,
        division: division!,
        house: house!,
        medium: medium,
        batch: batch,
        motherTongue: motherTongue,

        fatherName: fatherCtrl.text.trim(),

        primaryMobile: primaryMobileCtrl.text.trim(),
        secondaryMobile: secondaryMobileCtrl.text.trim().isEmpty
            ? null
            : secondaryMobileCtrl.text.trim(),

        profile: Profile(
          motherName: motherCtrl.text.trim(),
          guardianName: guardianNameCtrl.text.trim().isEmpty
              ? null
              : guardianNameCtrl.text.trim(),
          guardianRelation: null,
          religion: _nullIfEmpty(religionCtrl.text),
          community: community,
          caste: casteCtrl.text.trim().isEmpty ? null : casteCtrl.text.trim(),
          bloodGroup: bloodGroup,
          appInstalled: false,
        ),

        address: Address(
          commAddressLine1: communicationAddressCtrl.text.trim(),
          commAddressLine2: null,
          commCity: communicationAddressCtrl.text.trim(),
          commPincode: '000000',

          permAddressLine1: permanentAddressCtrl.text.trim(),
          permAddressLine2: null,
          permCity: permanentAddressCtrl.text.trim(),
          permPincode: '000000',
        ),

        identifiers: Identifiers(
          aadhaar: _nullIfEmpty(aadhaarCtrl.text),
          emis: emisCtrl.text.trim().isEmpty ? null : emisCtrl.text.trim(),
          apar: apaarCtrl.text.trim().isEmpty ? null : apaarCtrl.text.trim(),
          udis: udiseCtrl.text.trim().isEmpty ? null : udiseCtrl.text.trim(),
        ),
      );

      if (widget.scholar == null) {
        // CREATE
        await service.create(scholar);
      } else {
        // UPDATE
        await service.update(widget.scholar!.id, scholar);
      }

      await _uploadPhotoIfNeeded();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved successfully')));

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('SAVE ERROR → $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
