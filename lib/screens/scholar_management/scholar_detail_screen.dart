import 'package:flutter/material.dart';
import 'models/scholar_model.dart';

class ScholarDetailScreen extends StatelessWidget {
  final Scholar scholar;

  const ScholarDetailScreen({super.key, required this.scholar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scholar Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Admission No', scholar.admNo),
            _row('Name', scholar.name),
            _row('Class', '${scholar.className}-${scholar.section}'),
            _row('Gender', scholar.gender),
            _row('Mobile', scholar.mobile),
            _row('Father Name', scholar.fatherName),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text('$label: $value',
          style: const TextStyle(fontSize: 16)),
    );
  }
}
