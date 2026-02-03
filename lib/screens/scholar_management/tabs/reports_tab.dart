import 'package:flutter/material.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  String? reportType;

  static const teal = Color(0xFF009688);

  final List<String> reportTypes = [
    'Student List',
    'Class Wise Strength',
    'Gender Wise Report',
    'Transport Report',
    'Community Report',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),

          const SizedBox(height: 16),

          Expanded(child: _content()),
        ],
      ),
    );
  }

  /* ================= TOP BAR ================= */

  Widget _topBar() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: reportType,
            decoration: const InputDecoration(
              labelText: 'Report Type*',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: reportTypes
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => reportType = v),
          ),
        ),
        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: reportType == null ? null : _downloadReport,
          icon: const Icon(Icons.download),
          label: const Text('Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  /* ================= CONTENT ================= */

  Widget _content() {
    if (reportType == null) {
      return const Center(
        child: Text(
          'Pick a report type to begin',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return _reportPreview();
  }

  /* ================= PREVIEW ================= */

  Widget _reportPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reportType!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Report preview will be shown here.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          const Expanded(
            child: Center(
              child: Text(
                'No data loaded',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= ACTION ================= */

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$reportType downloaded'),
      ),
    );
  }
}
