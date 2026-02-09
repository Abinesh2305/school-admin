import 'package:flutter/material.dart';

import '../../scholar_management/scholar_service.dart';
import '../alumni_service.dart';
import '../models/alumni_model.dart';
import '../../scholar_management/models/scholar_model.dart';

const Color kTeal = Color(0xFF009688);

class AlumniTab extends StatefulWidget {
  const AlumniTab({super.key});

  @override
  State<AlumniTab> createState() => _AlumniTabState();
}

class _AlumniTabState extends State<AlumniTab> {
  final _alumniService = AlumniService();
  final _scholarService = ScholarService();

  final _idCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  /* ================= STATE ================= */

  Scholar? student;

  List<Alumni> alumniList = [];

  bool loadingStudent = false;
  bool loadingList = false;
  bool marking = false;

  int page = 1;
  int pageSize = 20;

  /* ================= INIT ================= */

  @override
  void initState() {
    super.initState();
    _loadAlumni();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _dateCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  /* ================= LOAD STUDENT ================= */

  Future<void> _loadStudent() async {
    final id = int.tryParse(_idCtrl.text.trim());

    if (id == null) {
      _show('Enter valid Student ID');
      return;
    }

    setState(() {
      loadingStudent = true;
      student = null;
    });

    try {
      final s = await _scholarService.getById(id);

      if (!mounted) return;

      setState(() => student = s);
    } catch (e) {
      _show('Student not found');
    }

    if (mounted) setState(() => loadingStudent = false);
  }

  /* ================= PICK DATE ================= */

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      _dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  /* ================= MARK ================= */

  Future<void> _markAlumni() async {
    if (student == null) {
      _show('Search student first');
      return;
    }

    if (_dateCtrl.text.isEmpty || _reasonCtrl.text.trim().isEmpty) {
      _show('Fill all fields');
      return;
    }

    if (marking) return;

    setState(() => marking = true);

    try {
      await _alumniService.mark(
        ids: [student!.id],
        leavingDate: _dateCtrl.text,
        reason: _reasonCtrl.text.trim(),
      );

      if (!mounted) return;

      _show('Marked as Alumni');

      _resetMarkForm();

      await _loadAlumni(); // 🔥 reload list
    } catch (e) {
      _show('Mark failed: $e');
    }

    if (mounted) setState(() => marking = false);
  }

  void _resetMarkForm() {
    _idCtrl.clear();
    _dateCtrl.clear();
    _reasonCtrl.clear();

    setState(() => student = null);
  }

  /* ================= LOAD ALUMNI ================= */

  Future<void> _loadAlumni() async {
    if (!mounted) return;

    setState(() => loadingList = true);

    try {
      final data = await _alumniService.getAll(page: page, pageSize: pageSize);

      if (!mounted) return;

      setState(() => alumniList = data);
    } catch (e) {
      _show('Load failed: $e');
    }

    if (mounted) setState(() => loadingList = false);
  }

  /* ================= REVERT ================= */

  Future<void> _revertDialog(int id) async {
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revert Alumni'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;

              await _alumniService.revert(
                ids: [id],
                reason: reasonCtrl.text.trim(),
              );

              if (!mounted) return;

              Navigator.pop(context);

              _show('Reverted');

              _loadAlumni();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _markSection(),

          const SizedBox(height: 16),

          const Divider(),

          const SizedBox(height: 10),

          _alumniSection(),
        ],
      ),
    );
  }

  /* ================= MARK UI ================= */

  Widget _markSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark Student as Alumni',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTeal,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Student ID',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: _loadStudent,
                  style: ElevatedButton.styleFrom(backgroundColor: kTeal),
                  child: const Text('Find'),
                ),
              ],
            ),

            if (loadingStudent)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(color: kTeal),
              ),

            if (student != null) _studentCard(),

            if (student != null) _markForm(),
          ],
        ),
      ),
    );
  }

  Widget _studentCard() {
    final s = student!;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: kTeal,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(s.fullName),
        subtitle: Text(
          'Adm: ${s.admissionNo} | Class: ${s.classId}-${s.sectionId}',
        ),
      ),
    );
  }

  Widget _markForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          TextField(
            controller: _dateCtrl,
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(
              labelText: 'Leaving Date',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: marking ? null : _markAlumni,
              icon: const Icon(Icons.school),
              label: const Text('Mark Alumni'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= ALUMNI LIST ================= */

  Widget _alumniSection() {
    return Expanded(
      child: Card(
        child: Column(
          children: [
            ListTile(
              title: const Text(
                'Alumni List',
                style: TextStyle(fontWeight: FontWeight.w600, color: kTeal),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAlumni,
              ),
            ),

            const Divider(height: 1),

            Expanded(child: _alumniTable()),
          ],
        ),
      ),
    );
  }

  Widget _alumniTable() {
    if (loadingList) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (alumniList.isEmpty) {
      return const Center(child: Text('No Alumni Found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Admission')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Leaving')),
          DataColumn(label: Text('Reason')),
          DataColumn(label: Text('Action')),
        ],
        rows: List.generate(alumniList.length, (i) {
          final a = alumniList[i];

          return DataRow(
            cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Text(a.displayName)),
              DataCell(Text(a.admissionNo)),
              DataCell(Text('${a.classId}-${a.sectionId}')),
              DataCell(Text(a.leavingDate)),
              DataCell(
                SizedBox(
                  width: 160,
                  child: Text(
                    a.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.red),
                  tooltip: 'Revert Alumni',
                  onPressed: () => _revertDialog(a.studentId),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /* ================= HELPER ================= */

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
