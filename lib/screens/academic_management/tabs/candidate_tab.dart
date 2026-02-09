import 'package:flutter/material.dart';

import '../models/candidate_model.dart';
import '../candidate_service.dart';
import '../add_edit_candidate_screen.dart';

class CandidateTab extends StatefulWidget {
  const CandidateTab({super.key});

  @override
  State<CandidateTab> createState() => _CandidateTabState();
}

class _CandidateTabState extends State<CandidateTab> {
  final _service = CandidateService();

  List<Candidate> candidates = [];

  int page = 1;
  int pageSize = 20;
  int total = 0;

  String search = '';

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  // ================= LOAD =================

  Future<void> _loadCandidates() async {
    setState(() => loading = true);

    try {
      final res = await _service.getCandidates(
        q: search,
        page: page,
        pageSize: pageSize,
      );

      final items = res['items'] as List;

      candidates = items.map((e) => Candidate.fromJson(e)).toList();

      total = res['total'];
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => loading = false);
  }

  // ================= DELETE =================

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Candidate"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _service.delete(id);

    _loadCandidates();
  }

  // ================= CONVERT =================

  Future<void> _convert(Candidate c) async {
    try {
      final empCode = "EMP${DateTime.now().millisecondsSinceEpoch}";

      final data = {
        "candidateId": c.id,
        "fullName": c.fullName,
        "employeeCode": empCode, //  UNIQUE
        "phone": c.phone,
        "email": c.email,
        "roleName": "Teacher",
        "roleKey": "teacher",
        "dateOfJoin": DateTime.now().toIso8601String().substring(0, 10),

        "createLogin": true,
        "tempPassword": "teacher@123",

        "allowPermissions": [],
        "denyPermissions": [],
        "classSectionMappings": [],
        "subjectMappings": [],
      };

      await _service.convertToStaff(data);

      _show("Converted to Staff Successfully");

      _loadCandidates(); // refresh list
    } catch (e) {
      _show("Convert failed");
      debugPrint("Convert Error: $e");
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterBar(),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : _table(),
        ),

        _pagination(),
      ],
    );
  }

  // ================= FILTER =================

  Widget _filterBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search candidate",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) {
                search = v;
                page = 1;
                _loadCandidates();
              },
            ),
          ),

          const SizedBox(width: 10),

          ElevatedButton.icon(
            onPressed: () async {
              final ok = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditCandidateScreen(),
                ),
              );

              if (ok == true) {
                _loadCandidates();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ================= TABLE =================

  Widget _table() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),

        columns: const [
          DataColumn(label: Text("S.No")),
          DataColumn(label: Text("Name")),
          DataColumn(label: Text("Mobile")),
          DataColumn(label: Text("Email")),
          DataColumn(label: Text("Stage")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Actions")),
        ],

        rows: List.generate(candidates.length, (i) {
          final c = candidates[i];

          return DataRow(
            cells: [
              DataCell(Text("${i + 1}")),

              DataCell(Text(c.fullName)),

              DataCell(Text(c.phone)),

              DataCell(Text(c.email)),

              DataCell(Text(_stageText(c.stage))),

              DataCell(
                Icon(
                  c.isActive ? Icons.check_circle : Icons.cancel,
                  color: c.isActive ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),

              DataCell(
                Row(
                  children: [
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () async {
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditCandidateScreen(candidate: c),
                          ),
                        );

                        if (ok == true) {
                          _loadCandidates();
                        }
                      },
                    ),

                    // Convert
                    IconButton(
                      icon: const Icon(Icons.sync_alt, size: 18),
                      onPressed: () => _convert(c),
                    ),

                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _delete(c.id),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ================= PAGINATION =================

  Widget _pagination() {
    final totalPages = (total / pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1
                ? () {
                    page--;
                    _loadCandidates();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),

          Text("Page $page of $totalPages"),

          IconButton(
            onPressed: page < totalPages
                ? () {
                    page++;
                    _loadCandidates();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  String _stageText(int s) {
    switch (s) {
      case 1:
        return "Applied";
      case 2:
        return "Interview";
      case 3:
        return "Selected";
      default:
        return "-";
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
