import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'staff_management_screen.dart';
import 'class_section_grid_screen.dart.dart';
import 'subject_master_screen.dart';
import 'teacher_mapping_screen.dart ';

class AcademicManagementScreen extends StatelessWidget {
  const AcademicManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> academicItems = [
      {
        'icon': Icons.people_outline,
        'label': 'Staff Management',
        'action': 'staff',
      },
      {
        'icon': Icons.class_outlined,
        'label': 'Class & Section Masters',
        'action': 'classSection',
      },
      {
        'icon': Icons.book_outlined,
        'label': 'Subject Masters',
        'action': 'subject',
      },
      {
        'icon': Icons.assignment_ind_outlined,
        'label': 'Teacher Mapping & Relieving',
        'action': 'teacher',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Academic Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: academicItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 👈 2 icons per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = academicItems[index];

            return _buildItem(
              icon: item['icon'],
              label: item['label'],
              colorScheme: cs,
              onTap: () => _handleAction(context, item['action']),
            );
          },
        ),
      ),
    );
  }

  /* ================= ACTION HANDLER ================= */

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'staff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
        );
        break;

      case 'classSection':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClassSectionGridScreen()),
        );
        break;

      case 'subject':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubjectMasterScreen()),
        );
        break;
        case 'teacher':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TeacherMappingScreen(),
        ),
      );
      break;
    }
  }

  /* ================= TILE ================= */

  Widget _buildItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: colorScheme.primary),
              const SizedBox(height: 10),
              AutoSizeText(
                label,
                maxLines: 2,
                minFontSize: 12,
                maxFontSize: 14,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
