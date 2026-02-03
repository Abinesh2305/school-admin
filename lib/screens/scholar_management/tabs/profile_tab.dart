import 'package:flutter/material.dart';
import '../models/scholar_model.dart';
import '../add_edit_scholar_screen.dart';
import '../scholar_detail_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

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
        DataCell(Text(s.admNo)),
        DataCell(Text(s.name)),
        DataCell(Text(s.className)),
        DataCell(Text(s.section)),
        DataCell(Text(s.gender)),
        DataCell(Text(s.mobile)),
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

class _ProfileTabState extends State<ProfileTab> {
  final List<Scholar> _allScholars = [
    Scholar(
      admNo: 'DA-1002',
      name: 'I User 2',
      className: 'I',
      section: 'A',
      gender: 'Male',
      mobile: '9489681411',
      fatherName: 'Father K-2',
    ),
  ];

  List<Scholar> _filtered = [];

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

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_allScholars);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        const SizedBox(height: 8),
        Expanded(child: _buildTable()),
      ],
    );
  }

  /* ================= FILTER BAR ================= */

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
          // ================= ROW 1 =================
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

          // ================= ROW 2 =================
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

          // ================= ROW 3 =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: _openMoreFilters,
                child: const Text('More Filters'),
              ),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addScholar,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text(
                      'Add Scholar',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openMoreFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== HEADER =====
                    Row(
                      children: const [
                        Icon(Icons.filter_list, color: Color(0xFF009688)),
                        SizedBox(width: 8),
                        Text(
                          'More Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ===== FILTERS =====
                    _filterGrid([
                      _filterDropdown('Gender', gender, [
                        'All',
                        'Male',
                        'Female',
                      ], (v) => setState(() => gender = v)),

                      _filterDropdown(
                        'App Installed',
                        appInstalled,
                        ['All', 'Yes', 'No'],
                        (v) => setState(() => appInstalled = v),
                      ),

                      _filterDropdown(
                        'Scholar Category',
                        scholarCategory,
                        ['All', 'General', 'OBC', 'SC', 'ST'],
                        (v) => setState(() => scholarCategory = v),
                      ),

                      _filterDropdown(
                        'Admission Type',
                        admissionType,
                        ['All', 'New', 'Transfer'],
                        (v) => setState(() => admissionType = v),
                      ),

                      _filterDropdown('House', house, [
                        'All',
                        'Red',
                        'Blue',
                        'Green',
                      ], (v) => setState(() => house = v)),

                      _filterDropdown(
                        'Transport Type',
                        transportType,
                        ['All', 'Bus', 'Van', 'Own'],
                        (v) => setState(() => transportType = v),
                      ),

                      _filterDropdown('Division', division, [
                        'All',
                        'Primary',
                        'Secondary',
                      ], (v) => setState(() => division = v)),

                      _filterDropdown(
                        'Scholar Type',
                        scholarType,
                        ['All', 'Day Scholar', 'Hostel'],
                        (v) => setState(() => scholarType = v),
                      ),

                      _filterDropdown('Community', community, [
                        'All',
                        'OC',
                        'BC',
                        'MBC',
                        'SC',
                        'ST',
                      ], (v) => setState(() => community = v)),

                      _filterDropdown('Specific', specific, [
                        'All',
                        'Yes',
                        'No',
                      ], (v) => setState(() => specific = v)),
                    ]),

                    const SizedBox(height: 24),

                    // ===== ACTIONS =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _resetMoreFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /* ================= TABLE ================= */

  Widget _buildTable() {
    if (_filtered.isEmpty) {
      return const Center(child: Text('No scholars found'));
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // ❌ remove row lines
        dataTableTheme: const DataTableThemeData(dividerThickness: 0),
      ),
      child: PaginatedDataTable(
        header: const Text(
          'Scholars',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        rowsPerPage: 5,
        availableRowsPerPage: const [5, 10, 20],
        columnSpacing: 28,
        showCheckboxColumn: false, // cleaner look
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

  /* ================= FILTER LOGIC ================= */

  void _applyFilters() {
    setState(() {
      _filtered = _allScholars.where((s) {
        final classOk =
            selectedClass == 'All Classes' || s.className == selectedClass;
        final sectionOk =
            selectedSection == 'All Sections' || s.section == selectedSection;
        final searchOk =
            search.isEmpty ||
            s.name.toLowerCase().contains(search.toLowerCase()) ||
            s.admNo.toLowerCase().contains(search.toLowerCase());
        return classOk && sectionOk && searchOk;
      }).toList();
    });
  }

  /* ================= CRUD ================= */

  void _addScholar() async {
    final result = await Navigator.push<Scholar>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditScholarScreen()),
    );

    if (result != null) {
      setState(() {
        _allScholars.add(result);
        _applyFilters();
      });
    }
  }

  void _editScholar(int index) async {
    final updated = await Navigator.push<Scholar>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScholarScreen(scholar: _filtered[index]),
      ),
    );

    if (updated != null) {
      final realIndex = _allScholars.indexWhere(
        (e) => e.admNo == updated.admNo,
      );
      setState(() {
        _allScholars[realIndex] = updated;
        _applyFilters();
      });
    }
  }

  void _deleteScholar(int index) {
    final scholar = _filtered[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Scholar'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allScholars.removeWhere((e) => e.admNo == scholar.admNo);
                _applyFilters();
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewScholar(Scholar scholar) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScholarDetailScreen(scholar: scholar)),
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

  /* ================= COMMON ================= */

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 160,
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

  Widget _filterGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 600;

        return GridView.count(
          crossAxisCount: isWide ? 2 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 6,
          childAspectRatio: 3.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
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
