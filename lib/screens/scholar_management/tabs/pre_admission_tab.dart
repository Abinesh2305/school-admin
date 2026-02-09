import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/preadmission_model.dart';
import '../preadmission_service.dart';

class PreAdmissionTab extends StatefulWidget {
  const PreAdmissionTab({super.key});

  @override
  State<PreAdmissionTab> createState() => _PreAdmissionTabState();
}

class _PreAdmissionTabState extends State<PreAdmissionTab> {
  final _service = PreadmissionService();

  static const teal = Color(0xFF009688);

  List<Preadmission> list = [];

  bool loading = false;

  String search = '';

  int page = 1;
  final int pageSize = 20;

  /* ================= INIT ================= */

  @override
  void initState() {
    super.initState();
    _load();
  }

  /* ================= LOAD ================= */

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      final data = await _service.getAll(
        page: page,
        pageSize: pageSize,
        status: 'all',
      );

      setState(() => list = data);
    } catch (e) {
      _toast('Load failed: $e');
    }

    setState(() => loading = false);
  }

  /* ================= ADD ================= */

  Future<void> _addDialog() async {
    final first = TextEditingController();
    final middle = TextEditingController();
    final last = TextEditingController();

    final mobile = TextEditingController();
    final altMobile = TextEditingController();
    final email = TextEditingController();

    final father = TextEditingController();
    final mother = TextEditingController();

    final dob = TextEditingController();

    final classId = TextEditingController(text: "1");
    final sectionId = TextEditingController(text: "1");

    final address1 = TextEditingController();
    final city = TextEditingController();

    final notes = TextEditingController();

    String gender = "Male";

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Pre-Admission"),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ================= NAME =================
              _field(first, "First Name *"),
              _field(middle, "Middle Name"),
              _field(last, "Last Name *"),

              // ================= CONTACT =================
              _field(mobile, "Mobile *"),
              _field(altMobile, "Alternate Mobile"),
              _field(email, "Email"),

              // ================= DOB =================
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDate: DateTime(2012),
                  );

                  if (date != null) {
                    dob.text = date.toIso8601String().substring(0, 10);
                  }
                },
                child: AbsorbPointer(child: _field(dob, "DOB * (yyyy-MM-dd)")),
              ),

              // ================= GENDER =================
              DropdownButtonFormField(
                initialValue: gender,
                decoration: _dec("Gender"),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                ],
                onChanged: (v) => gender = v!,
              ),

              const SizedBox(height: 10),

              // ================= PARENTS =================
              _field(father, "Father Name *"),
              _field(mother, "Mother Name *"),

              // ================= CLASS / SECTION =================
              _field(classId, "Class ID *"),
              _field(sectionId, "Section ID *"),

              // ================= ADDRESS =================
              _field(address1, "Address Line"),
              _field(city, "City"),

              // ================= NOTES =================
              _field(notes, "Notes"),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: teal),

            child: const Text("Create"),

            onPressed: () async {
              // ========== VALIDATION ==========
              if (first.text.isEmpty ||
                  last.text.isEmpty ||
                  mobile.text.length != 10 ||
                  father.text.isEmpty ||
                  mother.text.isEmpty ||
                  dob.text.isEmpty) {
                _toast("Fill all required fields");
                return;
              }

              Navigator.pop(context);

              await _createFull(
                first.text,
                middle.text,
                last.text,
                mobile.text,
                altMobile.text,
                email.text,
                dob.text,
                gender,
                father.text,
                mother.text,
                classId.text,
                sectionId.text,
                address1.text,
                city.text,
                notes.text,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createFull(
    String first,
    String middle,
    String last,
    String mobile,
    String altMobile,
    String email,
    String dob,
    String gender,
    String father,
    String mother,
    String classId,
    String sectionId,
    String address1,
    String city,
    String notes,
  ) async {
    try {
      final body = {
        "targetAcademicYearId": 9,

        "firstName": first,
        "middleName": middle.isEmpty ? null : middle,
        "lastName": last,

        "primaryMobile": mobile,
        "secondaryMobile": altMobile.isEmpty ? null : altMobile,
        "email": email.isEmpty ? null : email,

        "dob": dob,
        "gender": gender,

        "fatherName": father,
        "motherName": mother,

        "desiredClassId": int.parse(classId),
        "desiredSectionId": int.parse(sectionId),

        "addressJson": jsonEncode({"line1": address1, "city": city}),

        "notes": notes,
      };

      await _service.createRaw(body);

      _toast("Created Successfully");
      _load();
    } catch (e) {
      _toast("Create failed: $e");
    }
  }

  Future<void> _convert(
    int id,
    Map<String, dynamic> form,
    String admissionNo,
  ) async {
    try {
      final body = {
        "targetAcademicYearId": form["targetAcademicYearId"],
        "admissionNo": admissionNo,

        "firstName": form["firstName"],
        "middleName": null,
        "lastName": form["lastName"],

        "classId": form["classId"],
        "sectionId": form["sectionId"],

        "gender": form["gender"],
        "dob": form["dob"],

        "fatherName": form["fatherName"],

        "primaryMobile": form["primaryMobile"],
        "secondaryMobile": form["secondaryMobile"],
      };

      final res = await _service.convert(id: id, body: body);

      final studentId = res["studentId"];

      _toast('Converted Successfully');

      // ✅ Reload preadmissions (status changes)
      await _load();
    } catch (e) {
      _toast('Convert failed: $e');
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),

        const SizedBox(height: 12),

        Expanded(child: _table()),

        _pagination(),
      ],
    );
  }

  /* ================= HEADER ================= */

  Widget _header() {
    return Card(
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => search = v),

                decoration: _dec(
                  'Search name / mobile',
                ).copyWith(prefixIcon: const Icon(Icons.search)),
              ),
            ),

            const SizedBox(width: 12),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: teal),

              onPressed: _addDialog,

              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertDialog(int id) async {
    try {
      final form = await _service.getConvertForm(id);

      final admission = TextEditingController(
        text: form['suggestedAdmissionNo'],
      );

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Convert to Scholar'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: teal),
                title: Text(form['firstName'] ?? ''),
                subtitle: Text(form['primaryMobile'] ?? ''),
              ),

              _field(admission, 'Admission No'),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: teal),

              child: const Text('Convert'),

              onPressed: () async {
                if (admission.text.isEmpty) {
                  _toast('Admission No required');
                  return;
                }

                Navigator.pop(context);

                await _convert(id, form, admission.text);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      _toast('Convert failed: $e');
    }
  }

  /* ================= TABLE ================= */

  Widget _table() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = list.where((e) {
      return e.displayName.toLowerCase().contains(search.toLowerCase()) ||
          e.primaryMobile.contains(search);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No Records'));
    }

    return ListView.builder(
      itemCount: filtered.length,

      itemBuilder: (_, i) {
        final p = filtered[i];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: teal.withOpacity(.15),
              child: Text('${i + 1}'),
            ),

            title: Text(p.displayName),

            subtitle: Text(p.primaryMobile),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _status(p.status),

                if (p.status == 'draft')
                  IconButton(
                    icon: const Icon(Icons.person_add, color: teal),

                    onPressed: () => _convertDialog(p.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /* ================= STATUS ================= */

  Widget _status(String s) {
    Color c = Colors.grey;

    if (s == 'draft') c = Colors.orange;
    if (s == 'converted') c = teal;

    return Container(
      margin: const EdgeInsets.only(right: 6),

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: c.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        s.toUpperCase(),
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  /* ================= PAGINATION ================= */

  Widget _pagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),

          onPressed: page > 1
              ? () {
                  page--;
                  _load();
                }
              : null,
        ),

        Text('Page $page'),

        IconButton(
          icon: const Icon(Icons.chevron_right),

          onPressed: list.length == pageSize
              ? () {
                  page++;
                  _load();
                }
              : null,
        ),
      ],
    );
  }

  /* ================= HELPERS ================= */

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: TextField(controller: c, decoration: _dec(label)),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}
