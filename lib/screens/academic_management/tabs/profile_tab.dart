import 'package:flutter/material.dart';

import '../models/staff_model.dart';
import '../staff_service.dart';
import '../add_edit_staff_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _service = StaffService();

  List<Staff> staffList = [];

  int page = 1;
  int pageSize = 20;
  int total = 0;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  // ================= LOAD =================

  Future<void> _loadStaff() async {
    setState(() => loading = true);

    try {
      final res = await _service.getStaff(page: page, pageSize: pageSize);

      final items = res['items'] as List;

      staffList = items.map((e) => Staff.fromJson(e)).toList();

      total = res['total'];
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => loading = false);
  }

  // ================= ACTIVE TOGGLE =================

  Future<void> _toggleActive(Staff staff) async {
    await _service.setActive(staff.id, !staff.isActive);

    _loadStaff();
  }

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

  // ================= FILTER BAR =================

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
                hintText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _loadStaff(),
            ),
          ),

          const SizedBox(width: 10),

          ElevatedButton.icon(
            onPressed: () async {
              final ok = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditStaffScreen()),
              );

              if (ok == true) {
                _loadStaff(); // refresh list
              }
            },

            icon: const Icon(Icons.add),
            label: const Text("Add Teacher"),
          ),

          const SizedBox(width: 8),

          ElevatedButton(onPressed: () {}, child: const Text("Export")),
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
          DataColumn(label: Text("Emp ID")),
          DataColumn(label: Text("Name")),
          DataColumn(label: Text("Mobile")),
          DataColumn(label: Text("Email")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Actions")),
        ],
        rows: List.generate(staffList.length, (i) {
          final s = staffList[i];

          return DataRow(
            cells: [
              DataCell(Text("${i + 1}")),
              DataCell(Text(s.employeeCode)),
              DataCell(Text(s.fullName)),
              DataCell(Text(s.phone)),
              DataCell(Text(s.email)),

              // Status
              DataCell(
                Switch(value: s.isActive, onChanged: (_) => _toggleActive(s)),
              ),

              // Actions
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () async {
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditStaffScreen(
                              staff: s, 
                            ),
                          ),
                        );

                        if (ok == true) {
                          _loadStaff(); // refresh after edit
                        }
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () {
                        // View
                      },
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
                    _loadStaff();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),

          Text("Page $page of $totalPages"),

          IconButton(
            onPressed: page < totalPages
                ? () {
                    page++;
                    _loadStaff();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
