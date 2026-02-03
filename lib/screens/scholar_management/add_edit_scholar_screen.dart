import 'package:ClasteqSMS/screens/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'models/scholar_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddEditScholarScreen extends StatefulWidget {
  final Scholar? scholar;
  const AddEditScholarScreen({super.key, this.scholar});

  @override
  State<AddEditScholarScreen> createState() => _AddEditScholarScreenState();
}

class _AddEditScholarScreenState extends State<AddEditScholarScreen> {
  final _formKey = GlobalKey<FormState>();
  bool detailed = false;
  final ImagePicker _picker = ImagePicker();
  File? _studentImage;

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
  String admissionType = '';
  String scholarCategory = '';
  String scholarType = '';
  String division = '';
  String house = '';
  DateTime? doj;

  String medium = '';
  String batch = '';
  String motherTongue = '';

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
  String selectedClass = '';
  String section = '';

  @override
  void initState() {
    super.initState();
    final s = widget.scholar;
    if (s != null) {
      firstNameCtrl.text = s.name;
      admNoCtrl.text = s.admNo;
      fatherCtrl.text = s.fatherName;
      primaryMobileCtrl.text = s.mobile;
      gender = s.gender;
      selectedClass = s.className;
      section = s.section;

      _studentImage = s.studentImage;
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
            onPressed: _save,
            child: const Text(
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
                _dropdown('Class*', selectedClass, [
                  'I',
                  'II',
                  'III',
                ], (v) => setState(() => selectedClass = v)),
                _dropdown('Section*', section, [
                  'A',
                  'B',
                  'C',
                ], (v) => setState(() => section = v)),
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
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      validator: label.contains('*')
          ? (v) => v == null ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPick,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          initialDate: value ?? DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          value == null
              ? 'Select date'
              : '${value.day}-${value.month}-${value.year}',
        ),
      ),
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final scholar = Scholar(
      admNo: admNoCtrl.text.trim(),
      name: firstNameCtrl.text.trim(),
      className: selectedClass,
      section: section,
      gender: gender,
      mobile: primaryMobileCtrl.text.trim(),
      fatherName: fatherCtrl.text.trim(),
      studentImage: _studentImage,
    );

    Navigator.pop(context, scholar);
  }
}
