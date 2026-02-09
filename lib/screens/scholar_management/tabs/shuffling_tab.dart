import 'package:flutter/material.dart';
import '../../scholar_management/shuffling_service.dart';

import '../../scholar_management/scholar_service.dart';
import '../../scholar_management/models/scholar_model.dart';

const Color kTeal = Color(0xFF009688);

class ScholarShufflingScreen extends StatefulWidget {
  const ScholarShufflingScreen({super.key});

  @override
  State<ScholarShufflingScreen> createState() => _ScholarShufflingScreenState();
}

class _ScholarShufflingScreenState extends State<ScholarShufflingScreen> {
  final _scholarService = ScholarService();
  final _shuffleService = ShufflingService();

  // ================= DROPDOWNS =================

  int? fromClass, fromSection;
  int? toClass, toSection;

  // ================= DATA =================

  List<Scholar> students = [];
  final Set<int> selectedIds = {};

  bool loading = false;
  bool processing = false;

  // ================= LOAD STUDENTS =================

  Future<void> _loadStudents() async {
    if (fromClass == null || fromSection == null) return;

    setState(() {
      loading = true;
      students.clear();
      selectedIds.clear();
    });

    try {
      final list = await _scholarService.getAll(pageSize: 200);

      final filtered = list
          .where((s) => s.classId == fromClass && s.sectionId == fromSection)
          .toList();

      setState(() {
        students = filtered;
        loading = false;
      });
    } catch (e) {
      loading = false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load error: $e')));
    }
  }

  // ================= PREVIEW =================

  Future<void> _previewMove() async {
    if (selectedIds.isEmpty) return;

    setState(() => processing = true);

    try {
      final res = await _shuffleService.preview(
        fromClassId: fromClass!,
        fromSectionId: fromSection!,
        toClassId: toClass!,
        toSectionId: toSection!,
        studentIds: selectedIds.toList(),
      );

      setState(() => processing = false);

      _showPreviewDialog(res);
    } catch (e) {
      setState(() => processing = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
    }
  }

  // ================= COMMIT =================

  Future<void> _commitMove() async {
    setState(() => processing = true);

    try {
      final res = await _shuffleService.commit(
        fromClassId: fromClass!,
        fromSectionId: fromSection!,
        toClassId: toClass!,
        toSectionId: toSection!,
        reason: 'Section reshuffle',
        studentIds: selectedIds.toList(),
      );

      final batchId = res['batchId'];

      await _trackBatch(batchId);
    } catch (e) {
      setState(() => processing = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Move failed: $e')));
    }
  }

  // ================= TRACK STATUS =================

  Future<void> _trackBatch(int id) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));

      final res = await _shuffleService.getBatch(id);

      if (res['status'] == 'completed') {
        setState(() => processing = false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shuffle Completed')));

        _loadStudents();
        break;
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= BODY =================
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _moveCard(
                  title: 'Move From',
                  classValue: fromClass,
                  sectionValue: fromSection,
                  onClassChanged: (v) {
                    setState(() {
                      fromClass = v;
                      fromSection = null;
                      students.clear();
                    });
                  },
                  onSectionChanged: (v) {
                    setState(() => fromSection = v);
                    _loadStudents();
                  },
                ),

                const SizedBox(height: 16),

                _moveCard(
                  title: 'Move To',
                  classValue: toClass,
                  sectionValue: toSection,
                  onClassChanged: (v) {
                    setState(() {
                      toClass = v;
                      toSection = null;
                    });
                  },
                  onSectionChanged: (v) => setState(() => toSection = v),
                ),

                const SizedBox(height: 20),

                Expanded(child: _studentList()),
              ],
            ),
          ),
        ),

        // ================= BOTTOM =================
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(
            children: [
              Chip(
                label: Text('Selected: ${selectedIds.length}'),
                backgroundColor: kTeal.withOpacity(0.15),
                labelStyle: const TextStyle(color: kTeal),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed:
                    selectedIds.isEmpty ||
                        toClass == null ||
                        toSection == null ||
                        processing
                    ? null
                    : _previewMove,
                icon: processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.drive_file_move),
                label: const Text('Confirm Move'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  minimumSize: const Size(170, 40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= STUDENT LIST =================

  Widget _studentList() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fromClass == null || fromSection == null) {
      return const Center(child: Text('Select From Class & Section'));
    }

    if (students.isEmpty) {
      return const Center(child: Text('No students found'));
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (c, i) {
        final s = students[i];

        return CheckboxListTile(
          value: selectedIds.contains(s.id),
          title: Text(s.fullName),
          subtitle: Text(s.admissionNo),
          activeColor: kTeal,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                selectedIds.add(s.id);
              } else {
                selectedIds.remove(s.id);
              }
            });
          },
        );
      },
    );
  }

  // ================= MOVE CARD =================

  Widget _moveCard({
    required String title,
    required int? classValue,
    required int? sectionValue,
    required ValueChanged<int?> onClassChanged,
    required ValueChanged<int?> onSectionChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: kTeal.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTeal,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: classValue,
                    decoration: _input('Class'),
                    items: [1, 2, 3, 4, 5]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text('Class $e'),
                          ),
                        )
                        .toList(),
                    onChanged: onClassChanged,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: sectionValue,
                    decoration: _input('Section'),
                    items: classValue == null
                        ? []
                        : [1, 2, 3]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('Section $e'),
                                ),
                              )
                              .toList(),
                    onChanged: classValue == null ? null : onSectionChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kTeal),
      ),
    );
  }

  // ================= PREVIEW DIALOG =================

  void _showPreviewDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Preview Move'),
        content: Text(
          'Eligible: ${data['eligibleCount']}\n'
          'Ineligible: ${data['ineligibleCount']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _commitMove();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
