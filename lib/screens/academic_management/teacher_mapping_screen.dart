import 'package:flutter/material.dart';

import 'academic_service.dart';
import 'staff_maping_service.dart';

class TeacherMappingScreen extends StatefulWidget {
  const TeacherMappingScreen({super.key});

  @override
  State<TeacherMappingScreen> createState() => _TeacherMappingScreenState();
}

class _TeacherMappingScreenState extends State<TeacherMappingScreen> {
  /* ================= DATA ================= */

  List<dynamic> teachers = [];
  List<dynamic> classes = [];
  List<dynamic> sections = [];
  List<dynamic> subjects = [];

  int? selectedTeacherId;
  int? classId;
  int? sectionId;

  List<int> selectedSubjectIds = [];

  bool loading = false;

  /* ================= INIT ================= */

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => loading = true);

    await _loadTeachers();
    await _loadClasses();
    await _loadSubjects();

    setState(() => loading = false);
  }

  /* ================= LOADERS ================= */

  Future<void> _loadTeachers() async {
    try {
      final res = await StaffMappingService.getStaffList();

      setState(() {
        teachers = res['items'] ?? [];
      });
    } catch (e) {
      _show("Failed to load staff");
    }
  }

  Future<void> _loadClasses() async {
    try {
      final res = await AcademicService.getClassDropdown();

      setState(() {
        classes = res;
      });
    } catch (e) {
      _show("Failed to load classes");
    }
  }

  Future<void> _loadSubjects() async {
    final res = await AcademicService.getSubjectDropdown();

    setState(() {
      subjects = res;
    });
  }

  /* ================= LOAD MAPPING ================= */

  Future<void> _loadMapping(int staffId) async {

  setState(() => loading = true);

  try {

    final res =
        await StaffMappingService.getStaffMappings(
      staffId: staffId,
    );

    final List classMaps =
        res['classSectionMappings'] ?? [];

    final List subjectMaps =
        res['subjectMappings'] ?? [];

    //  CLEAR OLD DATA FIRST
    classId = null;
    sectionId = null;
    sections.clear();
    selectedSubjectIds.clear();

    //  ONLY IF DATA EXISTS
    if (classMaps.isNotEmpty) {

      classId = classMaps[0]['classId'];
      final mappedSectionId =
          classMaps[0]['sectionId'];

      final sec =
          await AcademicService.getSections(
        classId: classId!,
      );

      sections = sec['items'] ?? [];

      final exists = sections.any(
        (s) => s['id'] == mappedSectionId,
      );

      if (exists) {
        sectionId = mappedSectionId;
      }
    }

    //  SUBJECTS
    if (subjectMaps.isNotEmpty) {
      selectedSubjectIds = subjectMaps
          .map<int>((s) => s['subjectId'])
          .toList();
    }

  } catch (e) {

    debugPrint("LOAD MAPPING ERROR → $e");

    //  Only show real errors
    _show("Unable to load mapping");

  }

  setState(() => loading = false);
}


  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Mapping")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _teacherDropdown(),
                  const SizedBox(height: 12),

                  _classDropdown(),
                  const SizedBox(height: 12),

                  _sectionDropdown(),
                  const SizedBox(height: 16),

                  _subjectMultiSelect(),
                  const SizedBox(height: 24),

                  _actionButtons(),
                ],
              ),
            ),
    );
  }

  /* ================= DROPDOWNS ================= */

  Widget _teacherDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedTeacherId,

      decoration: const InputDecoration(
        labelText: "Teacher",
        border: OutlineInputBorder(),
      ),

      items: teachers.map((t) {
        return DropdownMenuItem<int>(
          value: t['id'],
          child: Text("${t['fullName']} (${t['employeeCode']})"),
        );
      }).toList(),

      onChanged: (v) async {
        selectedTeacherId = v;

        // Clear old data
        classId = null;
        sectionId = null;
        sections.clear();
        selectedSubjectIds.clear();

        if (v != null) {
          await _loadMapping(v);
        }

        setState(() {});
      },
    );
  }

  Widget _classDropdown() {
    return DropdownButtonFormField<int>(
      value: classId,

      decoration: const InputDecoration(
        labelText: "Class",
        border: OutlineInputBorder(),
      ),

      items: classes.map((c) {
        return DropdownMenuItem<int>(value: c['id'], child: Text(c['name']));
      }).toList(),

      onChanged: (v) async {
        classId = v;
        sectionId = null;
        sections.clear();

        if (v != null) {
          final res = await AcademicService.getSections(classId: v);

          sections = res['items'] ?? [];
        }

        setState(() {});
      },
    );
  }

  Widget _sectionDropdown() {
    return DropdownButtonFormField<int>(
      value: sectionId,

      decoration: const InputDecoration(
        labelText: "Section",
        border: OutlineInputBorder(),
      ),

      items: sections.map((s) {
        return DropdownMenuItem<int>(value: s['id'], child: Text(s['name']));
      }).toList(),

      onChanged: (v) {
        sectionId = v;
        setState(() {});
      },
    );
  }

  /* ================= SUBJECT MULTI SELECT ================= */

  Widget _subjectMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Subjects", style: TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 6,

          children: subjects.map((s) {
            final int id = s['id'];

            final bool selected = selectedSubjectIds.contains(id);

            return FilterChip(
              label: Text(s['name']),
              selected: selected,

              onSelected: (v) {
                if (v) {
                  selectedSubjectIds.add(id);
                } else {
                  selectedSubjectIds.remove(id);
                }

                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /* ================= ACTION BUTTONS ================= */

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),

            onPressed: _saveMapping,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_remove),
            label: const Text("Relieve"),

            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

            onPressed: _confirmRelieve,
          ),
        ),
      ],
    );
  }

  /* ================= SAVE ================= */

  Future<void> _saveMapping() async {
    if (selectedTeacherId == null ||
        classId == null ||
        sectionId == null ||
        selectedSubjectIds.isEmpty) {
      _show("Fill all fields");
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ Get full staff profile
      final staff = await StaffMappingService.getStaffById(selectedTeacherId!);

      // 2️⃣ Build full payload
      final data = {
        "id": staff['id'],
        "type": staff['type'],
        "fullName": staff['fullName'],
        "employeeCode": staff['employeeCode'],
        "phone": staff['phone'],
        "email": staff['email'],
        "roleName": staff['roleName'],
        "dateOfJoin": staff['dateOfJoin'],
        "createLogin": false,

        "classSectionMappings": [
          {"classId": classId, "sectionId": sectionId, "isClassTeacher": false},
        ],

        "subjectMappings": selectedSubjectIds.map((id) {
          return {"classId": classId, "sectionId": sectionId, "subjectId": id};
        }).toList(),
      };

      // 3️⃣ Save
      await StaffMappingService.saveStaff(data: data);

      _show("Saved Successfully");
    } catch (e) {
      debugPrint("SAVE ERROR → $e");
      _show("Save Failed");
    }

    setState(() => loading = false);
  }

  /* ================= RELIEVE ================= */

  void _confirmRelieve() {
    if (selectedTeacherId == null) {
      _show("Select Teacher");
      return;
    }

    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text("Relieve Staff"),

          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(labelText: "Reason"),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

              child: const Text("Confirm"),

              onPressed: () async {
                if (reasonCtrl.text.isEmpty) {
                  _show("Enter reason");
                  return;
                }

                try {
                  await StaffMappingService.relieveStaff(
                    staffId: selectedTeacherId!,
                    status: 2,
                    reason: reasonCtrl.text,
                  );

                  Navigator.pop(context);

                  _show("Staff Relieved");
                } catch (e) {
                  _show("Relieve Failed");
                }
              },
            ),
          ],
        );
      },
    );
  }

  /* ================= HELPERS ================= */

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
