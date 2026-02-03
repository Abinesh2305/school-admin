import 'package:flutter/material.dart';

import 'school_switch_api.dart';
import '../main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class SchoolSwitcherService {
  // =====================================================
  // MAIN ENTRY (Used From UI)
  // =====================================================

  static Future<void> showSwitcher(BuildContext context) async {
    final schools = await _getSchools(context);

    if (schools == null || schools.isEmpty) {
      _showMessage(context, "No schools found");
      return;
    }

    final selected = await _pickSchoolDialog(context, schools);

    if (selected == null) return;

    await _switchAndRestart(context, selected);

  }

  // =====================================================
  // GET SCHOOLS FROM STORAGE
  // =====================================================

  static Future<List?> _getSchools(BuildContext context) async {
    try {
      final box = Hive.box(AppConstants.storageBoxSettings);

      final schools = box.get(AppConstants.keySchools);

      debugPrint("🏫 LOADED SCHOOLS => $schools");

      if (schools == null) return null;

      return List.from(schools);
    } catch (e) {
      debugPrint("❌ LOAD SCHOOL ERROR: $e");
      return null;
    }
  }

  // =====================================================
  // PICK SCHOOL DIALOG
  // =====================================================

  static Future<Map<String, dynamic>?> _pickSchoolDialog(
    BuildContext context,
    List schools,
  ) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ================= HEADER =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Select School",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // ================= LIST =================
                Expanded(
                  child: ListView.builder(
                    itemCount: schools.length,
                    itemBuilder: (context, index) {
                      final s = Map<String, dynamic>.from(schools[index]);

                      return ListTile(
                        leading: const Icon(Icons.school),
                        title: Text(s['displayName'] ?? s['name'] ?? "Unknown"),
                        subtitle: Text("Code: ${s['code'] ?? ''}"),
                        onTap: () {
                          Navigator.pop(dialogContext, s);
                        },
                      );
                    },
                  ),
                ),

                // ================= FOOTER =================
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // SWITCH + RESTART
  // =====================================================

  static Future<void> _switchAndRestart(
  BuildContext context,
  Map<String, dynamic> school,
) async {
  // Show loader
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final int schoolId = school['schoolId'];

  final result = await SchoolSwitchApi.switchSchool(
    schoolId: schoolId,
  );

  Navigator.pop(context); // close loader

  if (!context.mounted) return;

  if (result['success'] == true) {
    debugPrint("✅ SCHOOL SWITCH SUCCESS");

    final box = Hive.box(AppConstants.storageBoxSettings);

    // ✅ Save active school
    await box.put(AppConstants.keyActiveSchool, {
      "schoolId": schoolId,
      "code": school['code'],
      "name": school['displayName'] ?? school['name'],
    });

    await box.put(AppConstants.keySchoolId, schoolId);

    debugPrint("🏫 ACTIVE SCHOOL SAVED");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(
          onToggleTheme: () {},
          onToggleLanguage: () {},
        ),
      ),
      (_) => false,
    );
  } else {
    _showMessage(
      context,
      result['message'] ?? "Switch failed",
    );
  }
}


  static Future<Map<String, dynamic>?> pickSchool(
    BuildContext context,
    List schools,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text("Select School"),
          children: schools.map<Widget>((s) {
            final school = Map<String, dynamic>.from(s);

            return SimpleDialogOption(
              child: Text(school['displayName'] ?? school['name'] ?? 'Unknown'),
              onPressed: () {
                Navigator.pop(dialogContext, school);
              },
            );
          }).toList(),
        );
      },
    );
  }

  // =====================================================
  // MESSAGE HELPER
  // =====================================================

  static void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
