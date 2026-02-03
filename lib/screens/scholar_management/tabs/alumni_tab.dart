import 'package:flutter/material.dart';

class AlumniTab extends StatefulWidget {
  const AlumniTab({super.key});

  @override
  State<AlumniTab> createState() => _AlumniTabState();
}

class _AlumniTabState extends State<AlumniTab> {
  String search = '';
  String exitType = 'All Exit Types';
  String selectedClass = 'All Classes';
  String? section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _filterBar(),
          const SizedBox(height: 24),
          Expanded(child: _emptyState()),
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
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: const InputDecoration(
                hintText:
                    'Search (name / admission no / father / mobile)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

          _dropdown(
            label: 'Exit Type',
            value: exitType,
            items: const [
              'All Exit Types',
              'Completed',
              'Transfer',
              'Dropout',
            ],
            onChanged: (v) => setState(() => exitType = v),
            width: 200,
          ),

          _dropdown(
            label: 'Class',
            value: selectedClass,
            items: const [
              'All Classes',
              'I',
              'II',
              'III',
              'IV',
              'V',
            ],
            onChanged: (v) {
              setState(() {
                selectedClass = v;
                section = null;
              });
            },
            width: 200,
          ),

          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: section,
              decoration: const InputDecoration(
                labelText: 'Section (pick class first)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: selectedClass == 'All Classes'
                  ? []
                  : ['A', 'B', 'C']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                      .toList(),
              onChanged: selectedClass == 'All Classes'
                  ? null
                  : (v) => setState(() => section = v),
            ),
          ),

          OutlinedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /* ================= EMPTY STATE ================= */

  Widget _emptyState() {
    return Center(
      child: Text(
        'No alumni found',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  /* ================= PAGINATION ================= */

  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.chevron_left),
          ),
          const Text(
            'Page 1',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /* ================= COMMON ================= */

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    double width = 180,
  }) {
    return SizedBox(
      width: width,
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
        onChanged: (v) => onChanged(v!),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      search = '';
      exitType = 'All Exit Types';
      selectedClass = 'All Classes';
      section = null;
    });
  }
}
