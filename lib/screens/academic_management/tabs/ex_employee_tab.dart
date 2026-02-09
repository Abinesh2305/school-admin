import 'package:flutter/material.dart';

import '../staff_maping_service.dart';

class ExEmployeeTab extends StatefulWidget {
  const ExEmployeeTab({super.key});

  @override
  State<ExEmployeeTab> createState() => _ExEmployeeTabState();
}

class _ExEmployeeTabState extends State<ExEmployeeTab> {
  List<dynamic> exEmployees = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadExEmployees();
  }

  /* ================= LOAD ================= */

  Future<void> _loadExEmployees() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final res = await StaffMappingService.getExEmployees();

      if (!mounted) return;

      setState(() {
        exEmployees = res['items'] ?? [];
      });
    } catch (e) {
      debugPrint("EX EMP ERROR → $e");

      if (mounted) {
        _show("Failed to load ex employees");
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (exEmployees.isEmpty) {
      return const Center(child: Text("No Ex-Employees Found"));
    }

    return RefreshIndicator(
      onRefresh: _loadExEmployees,

      child: ListView.builder(
        padding: const EdgeInsets.all(12),

        itemCount: exEmployees.length,

        itemBuilder: (context, index) {
          final emp = exEmployees[index];

          return _employeeCard(emp);
        },
      ),
    );
  }

  /* ================= CARD ================= */

  Widget _employeeCard(Map emp) {
    final photoUrl = emp['photoUrl'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),

      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

      child: ListTile(
        leading: CircleAvatar(
          radius: 24,

          backgroundImage: photoUrl != null && photoUrl.toString().isNotEmpty
              ? NetworkImage(photoUrl)
              : null,

          child: photoUrl == null || photoUrl.toString().isEmpty
              ? const Icon(Icons.person)
              : null,
        ),

        title: Text(
          emp['fullName'] ?? "No Name",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),

            Text("Code: ${emp['employeeCode'] ?? '-'}"),

            Text("Phone: ${emp['phone'] ?? '-'}"),

            Text("Email: ${emp['email'] ?? '-'}"),
          ],
        ),

        trailing: const Icon(Icons.block, color: Colors.red),
      ),
    );
  }

  /* ================= HELPERS ================= */

  void _show(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
