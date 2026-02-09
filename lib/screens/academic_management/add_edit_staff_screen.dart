import 'package:flutter/material.dart';

import 'staff_service.dart';
import 'models/staff_model.dart';

class AddEditStaffScreen extends StatefulWidget {
  final Staff? staff; // null = Add, not null = Edit

  const AddEditStaffScreen({super.key, this.staff});

  @override
  State<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends State<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StaffService();
  List<dynamic> academicYears = [];
  List<dynamic> roles = [];

  int? selectedYearId;
  String? selectedRoleKey;
  String? selectedRoleName;

  // Controllers
  final nameCtrl = TextEditingController();
  final empCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  

  DateTime? joinDate;

  bool saving = false;
  bool loading = false; // 🔹 for edit loader

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    _initLoad();
    // If Edit → Load full data from API
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    empCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAcademicYears() async {
    try {
      final res = await _service.getAcademicYears();

      setState(() {
        academicYears = res;

        // Auto select latest
        if (academicYears.isNotEmpty) {
          selectedYearId = academicYears.first['id'];
          _loadRoles(selectedYearId!);
        }
      });
    } catch (e) {
      _show("Failed to load academic years");
    }
  }

  Future<void> _loadRoles(int yearId) async {
    try {
      final res = await _service.getRoles(yearId);

      setState(() {
        roles = res;
      });
    } catch (e) {
      _show("Failed to load roles");
    }
  }

  Future<void> _initLoad() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Load years
      final years = await _service.getAcademicYears();
      academicYears = years;

      // 2️⃣ Load staff if edit
      if (widget.staff != null) {
        final res = await _service.getById(widget.staff!.id);

        nameCtrl.text = res['fullName'] ?? '';
        empCtrl.text = res['employeeCode'] ?? '';
        phoneCtrl.text = res['phone'] ?? '';
        emailCtrl.text = res['email'] ?? '';
         '';

        if (res['dateOfJoin'] != null) {
          joinDate = _parseDate(res['dateOfJoin']);
        }

        // Year
        selectedYearId = res['academicYearId'];

        // Role name from staff API
        final roleNameFromApi = res['roleName'];
        selectedRoleName = roleNameFromApi;

        // 3️⃣ Load roles AFTER year
        if (selectedYearId != null) {
          roles = await _service.getRoles(selectedYearId!);
        }

        // ✅ Find roleKey using roleName
        if (roleNameFromApi != null && roles.isNotEmpty) {
          final role = roles.firstWhere(
            (e) => e['name'] == roleNameFromApi,
            orElse: () => null,
          );

          if (role != null) {
            selectedRoleKey = role['slug'];
          }
        }
      }

      // 4️⃣ Add Mode → default year
      if (widget.staff == null && academicYears.isNotEmpty) {
        selectedYearId = academicYears.first['id'];
        roles = await _service.getRoles(selectedYearId!);
      }

      setState(() {});
    } catch (e) {
      _show("Failed to load data");
    }

    setState(() => loading = false);
  }

  // ================= LOAD DETAILS =================

  // ================= SAVE =================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (joinDate == null) {
      _show("Select joining date");
      return;
    }

    setState(() => saving = true);

    try {
      final data = {
        "id": widget.staff?.id, // null = add, id = edit
        "type": 0,
        "fullName": nameCtrl.text.trim(),
        "employeeCode": empCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "roleName": selectedRoleName,
        "roleKey": selectedRoleKey,
        "dateOfJoin": _formatDate(joinDate!),
        "departmentId": null,
        "employmentType": 1,
        
        "createLogin": false,
        "tempPassword": null,
        "allowPermissions": [],
        "denyPermissions": [],
        "classSectionMappings": [],
        "subjectMappings": [],
      };

      await _service.saveStaff(data);

      if (mounted) {
        Navigator.pop(context, true); // refresh list
      }
    } catch (e) {
      _show("Save failed");
    }

    setState(() => saving = false);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Teacher" : "Add Teacher")),

      // 🔹 Show loader when editing
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field("Full Name", nameCtrl),

                  _field("Employee Code", empCtrl),

                  _field("Mobile", phoneCtrl, keyboard: TextInputType.phone),

                  _field(
                    "Email",
                    emailCtrl,
                    keyboard: TextInputType.emailAddress,
                  ),

                 

                  const SizedBox(height: 10),

                  _datePicker(),

                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYearId,
                    decoration: const InputDecoration(
                      labelText: "Academic Year",
                      border: OutlineInputBorder(),
                    ),
                    items: academicYears.map((y) {
                      return DropdownMenuItem<int>(
                        value: y['id'],
                        child: Text(y['name'] ?? y['yearName'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;

                      setState(() {
                        selectedYearId = v;
                        selectedRoleKey = null;
                        roles.clear();
                      });

                      _loadRoles(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedRoleKey,
                    decoration: const InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                    ),
                    items: roles.map((r) {
                      return DropdownMenuItem<String>(
                        value: r['slug'], //  roleKey
                        child: Text(r['name']), //  roleName
                      );
                    }).toList(),
                    validator: (v) => v == null ? "Select Role" : null,
                    onChanged: (v) {
                      final role = roles.firstWhere((e) => e['slug'] == v);

                      setState(() {
                        selectedRoleKey = role['slug'];
                        selectedRoleName = role['name'];
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  saving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _save,
                          child: const Text("Save"),
                        ),
                ],
              ),
            ),
    );
  }

  // ================= TEXT FIELD =================

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ================= DATE PICKER =================

  Widget _datePicker() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Date of Join",
          border: OutlineInputBorder(),
        ),
        child: Text(joinDate == null ? "Select Date" : _formatDate(joinDate!)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: joinDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() => joinDate = date);
    }
  }

  // ================= HELPERS =================

  // API gives: 01-02-2026
  DateTime _parseDate(String d) {
    final p = d.split('-');

    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  String _formatDate(DateTime d) {
    return "${d.year}-${_two(d.month)}-${_two(d.day)}";
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
