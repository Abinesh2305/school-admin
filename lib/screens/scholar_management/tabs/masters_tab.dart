import 'package:flutter/material.dart';

import '../models/master_item.dart';
import 'master_service.dart';

class MastersTab extends StatefulWidget {
  const MastersTab({super.key});

  @override
  State<MastersTab> createState() => _MastersTabState();
}

class _MastersTabState extends State<MastersTab> {
  /* ================= MASTER KEYS ================= */

  /// title -> backend key
  final Map<String, String> masterKeys = {
    'Scholar Category': 'scholar_category',
    'Admission Type': 'admission_type',
    'Transport Mode': 'transport_mode',
    'Scholar Type': 'scholar_type',
    'Mother Tongue': 'mother_tongue',
    'House': 'house',
    'Division': 'division',
    'Batch': 'batch',
  };

  /* ================= DATA ================= */

  final Map<String, List<MasterItem>> masters = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAllMasters();
  }

  /* ================= SERVICE ================= */

  MasterService _service(String master) {
    final key = masterKeys[master]!;

    return MasterService(path: 'scholars/school/masters/$key', masterKey: key);
  }

  /* ================= LOAD ================= */

  Future<void> loadAllMasters() async {
    setState(() => loading = true);

    try {
      for (final entry in masterKeys.keys) {
        final service = _service(entry);

        final data = await service.getAll();

        masters[entry] = data;
      }
    } catch (e) {
      debugPrint('MASTER LOAD ERROR → $e');
    }

    setState(() => loading = false);
  }

  /* ================= ADD ================= */

  void addItem(String master) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => _dialog(
      title: 'Add $master',
      controller: controller,
      onSave: () async {
        final service = _service(master);

        // ✅ Get existing list
        final list = masters[master] ?? [];

    
        final nextOrder = list.isEmpty
            ? 0
            : list.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

        // ✅ Send with order
        await service.add(
          controller.text.trim(),
          nextOrder,
        );

        Navigator.pop(context);

        loadAllMasters();
      },
    ),
  );
}


  /* ================= EDIT ================= */

  void editItem(String master, MasterItem item) {
    final controller = TextEditingController(text: item.name);

    showDialog(
      context: context,
      builder: (_) => _dialog(
        title: 'Edit $master',
        controller: controller,
        onSave: () async {
          final service = _service(master);

          await service.update(item.id, controller.text.trim());

          Navigator.pop(context);

          loadAllMasters();
        },
      ),
    );
  }

  /* ================= TOGGLE ================= */

  Future<void> toggleItem(String master, MasterItem item) async {
    final service = _service(master);

    await service.toggle(item.id, !item.isActive);

    loadAllMasters();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Text(
                  'Masters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                ...masters.entries.map(
                  (e) => _masterCard(title: e.key, values: e.value),
                ),
              ],
            ),
    );
  }

  /* ================= CARD ================= */

  Widget _masterCard({
    required String title,
    required List<MasterItem> values,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(title),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((e) {
                return GestureDetector(
                  onLongPress: () => toggleItem(title, e),
                  child: Chip(
                    label: Text(e.name),

                    avatar: Icon(
                      e.isActive ? Icons.check_circle : Icons.cancel,
                      color: e.isActive ? Colors.green : Colors.red,
                      size: 18,
                    ),

                    deleteIcon: const Icon(Icons.edit),
                    onDeleted: () => editItem(title, e),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= HEADER ================= */

  Widget _header(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        const Spacer(),

        IconButton(
          tooltip: 'Add',
          onPressed: () => addItem(title),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  /* ================= DIALOG ================= */

  Widget _dialog({
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    return AlertDialog(
      title: Text(title),

      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter name',
          border: OutlineInputBorder(),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isEmpty) return;

            onSave();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
