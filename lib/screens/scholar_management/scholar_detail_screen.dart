import 'package:flutter/material.dart';
import 'models/scholar_model.dart';
import 'add_edit_scholar_screen.dart';

class ScholarDetailScreen extends StatelessWidget {
  final Scholar scholar;

  const ScholarDetailScreen({super.key, required this.scholar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholar Details'),

        
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ok = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditScholarScreen(
                    scholar: scholar, 
                  ),
                ),
              );

              if (ok == true) {
                Navigator.pop(context, true); 
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= BASIC =================
            _section('Basic Info'),
            _row('Admission No', scholar.admissionNo),
            _row('Name', scholar.fullName),
            _row('Gender', scholar.gender),
            _row('DOB', scholar.dob ?? '-'),

            const Divider(),

            // ================= CLASS =================
            _section('Class Info'),
            _row('Class ID', scholar.classId.toString()),
            _row('Section ID', scholar.sectionId.toString()),

            const Divider(),

            // ================= CONTACT =================
            _section('Contact'),
            _row('Primary Mobile', scholar.primaryMobile),
            _row('Secondary Mobile', scholar.secondaryMobile ?? '-'),

            const Divider(),

            // ================= PARENTS =================
            _section('Parents'),
            _row('Father', scholar.fatherName),
            _row('Mother', scholar.profile?.motherName ?? '-'),

            const Divider(),

            // ================= PROFILE =================
            _section('Profile'),

            _row('Religion', scholar.profile?.religion ?? '-'),

            _row('Community', scholar.profile?.community ?? '-'),

            _row('Blood Group', scholar.profile?.bloodGroup ?? '-'),

            const Divider(),

            // ================= ADDRESS =================
            _section('Address'),

            _row('Communication', scholar.address?.commCity ?? '-'),

            _row('Permanent', scholar.address?.permCity ?? '-'),

            const Divider(),

            // ================= IDS =================
            _section('Identifiers'),

            _row('Aadhaar', scholar.identifiers?.aadhaar ?? '-'),
          ],
        ),
      ),
    );
  }

  /* ================= SECTION TITLE ================= */

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }

  /* ================= ROW ================= */

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Value
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
