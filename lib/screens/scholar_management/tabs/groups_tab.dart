import 'package:flutter/material.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  static const teal = Color(0xFF009688);

  String groupType = 'All Types';
  String category = 'All Categories';
  String search = '';

  final List<Map<String, String>> groups = [
    {
      'name': 'NEET Check',
      'type': 'Temporary',
      'category': 'Scholar',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _filterBar(),
          const SizedBox(height: 16),
          Expanded(child: _table()),
          const SizedBox(height: 12),
          _pagination(),
        ],
      ),
    );
  }

  /* ================= FILTER BAR ================= */

  Widget _filterBar() {
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

          return isMobile ? _filterColumn() : _filterRow();
        },
      ),
    );
  }

  /// ===== MOBILE (COLUMN) =====
  Widget _filterColumn() {
    return Column(
      children: [
        _dropdown(
          label: 'Group Type',
          value: groupType,
          items: const ['All Types', 'Temporary', 'Permanent'],
          onChanged: (v) => setState(() => groupType = v!),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Category',
          value: category,
          items: const ['All Categories', 'Scholar', 'Staff'],
          onChanged: (v) => setState(() => category = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addGroup,
            icon: const Icon(Icons.add),
            label: const Text('Add Group'),
          ),
        ),
      ],
    );
  }

  /// ===== DESKTOP (ROW) =====
  Widget _filterRow() {
    return Row(
      children: [
        _dropdown(
          label: 'Group Type',
          value: groupType,
          items: const ['All Types', 'Temporary', 'Permanent'],
          onChanged: (v) => setState(() => groupType = v!),
        ),
        const SizedBox(width: 12),
        _dropdown(
          label: 'Category',
          value: category,
          items: const ['All Categories', 'Scholar', 'Staff'],
          onChanged: (v) => setState(() => category = v!),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _addGroup,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
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
          columns: const [
            DataColumn(label: Text('S.No')),
            DataColumn(label: Text('Group Name')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Action')),
          ],
          rows: List.generate(groups.length, (index) {
            final g = groups[index];
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(g['name']!)),
                DataCell(Text(g['type']!)),
                DataCell(Text(g['category']!)),
                DataCell(
                  Row(
                    children: const [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Icon(Icons.delete, size: 20, color: Colors.red),
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

  /* ================= PAGINATION ================= */

  Widget _pagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.chevron_left),
        SizedBox(width: 12),
        Text('Page 1', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(width: 12),
        Icon(Icons.chevron_right),
      ],
    );
  }

  /* ================= HELPERS ================= */

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _addGroup() {}
}
