import 'package:flutter/material.dart';

class PreAdmissionTab extends StatefulWidget {
  const PreAdmissionTab({super.key});

  @override
  State<PreAdmissionTab> createState() => _PreAdmissionTabState();
}

class _PreAdmissionTabState extends State<PreAdmissionTab> {
  String search = '';

  final List<Map<String, String>> records = [
    {
      'name': 'Abdullah Abdul Aziz',
      'father': 'Abdul Aziz',
      'mobile': '9944236775',
      'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _topBar(),
          const SizedBox(height: 16),
          Expanded(child: _table()),
          const SizedBox(height: 12),
          _pagination(),
        ],
      ),
    );
  }

  /* ================= TOP BAR ================= */

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return isMobile ? _topBarColumn() : _topBarRow();
        },
      ),
    );
  }

  /// ===== MOBILE (COLUMN) =====
  Widget _topBarColumn() {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Search (name / father / mobile)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addPreAdmission,
            icon: const Icon(Icons.add),
            label: const Text('Add Pre-Admission'),
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.download),
            label: const Text('Download Template'),
          ),
        ),
      ],
    );
  }

  /// ===== DESKTOP / TABLET (ROW) =====
  Widget _topBarRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
              hintText: 'Search (name / father / mobile)',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _addPreAdmission,
          icon: const Icon(Icons.add),
          label: const Text('Add Pre-Admission'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _downloadTemplate,
          icon: const Icon(Icons.download),
          label: const Text('Download Template'),
        ),
      ],
    );
  }

  /* ================= TABLE ================= */

  Widget _table() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          dataRowHeight: 56,
          columnSpacing: 40,
          columns: const [
            DataColumn(label: Text('S.No')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Father')),
            DataColumn(label: Text('Mobile')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: List.generate(records.length, (index) {
            final r = records[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(r['name']!)),
                DataCell(Text(r['father']!)),
                DataCell(Text(r['mobile']!)),
                DataCell(_statusChip(r['status']!)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /* ================= STATUS CHIP ================= */

  Widget _statusChip(String status) {
    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.orange),
      ),
      backgroundColor: Colors.orange.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.orange),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /* ================= PAGINATION ================= */

  Widget _pagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.chevron_left),
        SizedBox(width: 12),
        Text(
          'Page 1',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(width: 12),
        Icon(Icons.chevron_right),
      ],
    );
  }

  /* ================= ACTIONS ================= */

  void _addPreAdmission() {}
  void _downloadTemplate() {}
}
