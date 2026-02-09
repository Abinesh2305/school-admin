import 'package:flutter/material.dart';

import '../models/scholar_model.dart';
import '../add_edit_scholar_screen.dart';
import '../scholar_detail_screen.dart';
import '../scholar_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

/* ======================================================
                    TABLE SOURCE
   ====================================================== */

class ScholarDataSource extends DataTableSource {
  final List<Scholar> data;

  final void Function(Scholar) onView;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  ScholarDataSource({
    required this.data,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;

    final s = data[index];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${index + 1}')),

        DataCell(Text(s.admissionNo)),

        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: s.photoUrl != null
                    ? NetworkImage(s.photoUrl!)
                    : null,
                child: s.photoUrl == null
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),

              const SizedBox(width: 8),

              Expanded(child: Text(s.fullName)),
            ],
          ),
        ),

        DataCell(Text(s.classId.toString())),

        DataCell(Text(s.sectionId.toString())),

        DataCell(Text(s.gender)),

        DataCell(Text(s.primaryMobile)),

        DataCell(Text(s.fatherName)),

        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 18),
                onPressed: () => onView(s),
              ),

              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => onEdit(index),
              ),

              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => onDelete(index),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}

/* ======================================================
                    MAIN TAB
   ====================================================== */

class _ProfileTabState extends State<ProfileTab> {
  final ScholarService _service = ScholarService();

  List<Scholar> _allScholars = [];
  List<Scholar> _filtered = [];

  bool loading = true;

  /* ================= FILTERS ================= */

  String selectedClass = 'All Classes';
  String selectedSection = 'All Sections';

  String search = '';

  String gender = 'All';
  String appInstalled = 'All';
  String scholarCategory = 'All';
  String admissionType = 'All';
  String house = 'All';
  String transportType = 'All';
  String division = 'All';
  String scholarType = 'All';
  String community = 'All';
  String specific = 'All';

  /* ================= INIT ================= */

  @override
  void initState() {
    super.initState();
    _loadScholars();
  }

  /* ================= LOAD ================= */

  Future<void> _loadScholars() async {
    try {
      setState(() => loading = true);

      final data = await _service.getAll();

      setState(() {
        _allScholars = data;
        _filtered = List.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint('LOAD SCHOLARS ERROR → $e');

      setState(() => loading = false);
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildFilterBar(),

        const SizedBox(height: 8),

        Expanded(child: _buildTable()),
      ],
    );
  }

  /* ======================================================
                      FILTER BAR
     ====================================================== */

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),

        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ROW 1
          Row(
            children: [
              _dropdown(
                label: 'Class',
                value: selectedClass,

                items: const ['All Classes', 'I', 'II', 'III'],

                onChanged: (v) {
                  selectedClass = v!;
                  _applyFilters();
                },
              ),

              const SizedBox(width: 16),

              _dropdown(
                label: 'Section',
                value: selectedSection,

                items: const ['All Sections', 'A', 'B', 'C'],

                onChanged: (v) {
                  selectedSection = v!;
                  _applyFilters();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ROW 2
          Center(
            child: SizedBox(
              width: 420,

              child: TextField(
                onChanged: (v) {
                  search = v;
                  _applyFilters();
                },

                decoration: const InputDecoration(
                  hintText: 'Search name / admission no',

                  prefixIcon: Icon(Icons.search),

                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ROW 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              OutlinedButton(
                onPressed: _openMoreFilters,
                child: const Text('More Filters'),
              ),

              ElevatedButton.icon(
                onPressed: _addScholar,

                icon: const Icon(Icons.person_add, size: 18),

                label: const Text(
                  'Add Scholar',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ======================================================
                        TABLE
     ====================================================== */

  Widget _buildTable() {
    if (_filtered.isEmpty) {
      return const Center(child: Text('No scholars found'));
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,

        dataTableTheme: const DataTableThemeData(dividerThickness: 0),
      ),

      child: PaginatedDataTable(
        header: const Text(
          'Scholars',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        rowsPerPage: 5,

        availableRowsPerPage: const [5, 10, 20],

        showCheckboxColumn: false,

        columns: const [
          DataColumn(label: Text('S.No')),
          DataColumn(label: Text('Adm No')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Section')),
          DataColumn(label: Text('Gender')),
          DataColumn(label: Text('Mobile')),
          DataColumn(label: Text('Father Name')),
          DataColumn(label: Text('Actions')),
        ],

        source: ScholarDataSource(
          data: _filtered,

          onView: _viewScholar,
          onEdit: _editScholar,
          onDelete: _deleteScholar,
        ),
      ),
    );
  }

  /* ======================================================
                      FILTER LOGIC
     ====================================================== */

  void _applyFilters() {
    setState(() {
      _filtered = _allScholars.where((s) {
        final classOk =
            selectedClass == 'All Classes' ||
            s.classId.toString() == selectedClass;

        final sectionOk =
            selectedSection == 'All Sections' ||
            s.sectionId.toString() == selectedSection;

        final searchOk =
            search.isEmpty ||
            s.fullName.toLowerCase().contains(search.toLowerCase()) ||
            s.admissionNo.toLowerCase().contains(search.toLowerCase());

        return classOk && sectionOk && searchOk;
      }).toList();
    });
  }

  /* ======================================================
                        CRUD
     ====================================================== */

  Future<void> _addScholar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditScholarScreen()),
    );

    if (result != null) {
      await _loadScholars();
    }
  }

  Future<void> _editScholar(int index) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScholarScreen(scholar: _filtered[index]),
      ),
    );

    if (updated != null) {
      await _loadScholars();
    }
  }

  /* ================= DELETE ================= */

  void _deleteScholar(int index) {
    final scholar = _filtered[index];

    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text('Delete Scholar'),

        content: const Text('Are you sure you want to delete this scholar?'),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

            onPressed: () async {
              try {
                await _service.delete(scholar.id);

                await _loadScholars();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scholar deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delete failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },

            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /* ================= VIEW ================= */

  Future<void> _viewScholar(Scholar s) async {
    try {
      final full = await _service.getById(s.id);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScholarDetailScreen(scholar: full)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load details: $e')));
    }
  }

  /* ======================================================
                    MORE FILTERS
     ====================================================== */

  void _openMoreFilters() {
    showModalBottomSheet(
      context: context,

      builder: (_) => const SizedBox(
        height: 300,
        child: Center(child: Text('More filters (Coming soon)')),
      ),
    );
  }

  void _resetMoreFilters() {
    gender = 'All';
    appInstalled = 'All';
    scholarCategory = 'All';
    admissionType = 'All';
    house = 'All';
    transportType = 'All';
    division = 'All';
    scholarType = 'All';
    community = 'All';
    specific = 'All';
  }

  /* ======================================================
                    COMMON WIDGETS
     ====================================================== */

  Widget _dropdown({
    required String label,
    required String value,

    required List<String> items,

    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 160,

      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : null,

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

  Widget _filterGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,

      crossAxisSpacing: 12,
      mainAxisSpacing: 6,

      childAspectRatio: 3.2,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      children: children,
    );
  }

  Widget _filterDropdown(
    String label,
    String value,
    List<String> items,

    ValueChanged<String> onChanged,
  ) {
    const teal = Color(0xFF009688);

    return DropdownButtonFormField<String>(
      initialValue: value,

      decoration: InputDecoration(
        labelText: label,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),

          borderSide: const BorderSide(color: teal, width: 1.2),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),

          borderSide: const BorderSide(color: teal, width: 1.6),
        ),

        isDense: true,
      ),

      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),

      onChanged: (v) => onChanged(v!),
    );
  }
}
