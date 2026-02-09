import 'package:flutter/material.dart';

import 'candidate_service.dart';
import 'models/candidate_model.dart';

class AddEditCandidateScreen extends StatefulWidget {
  final Candidate? candidate;

  const AddEditCandidateScreen({super.key, this.candidate});

  @override
  State<AddEditCandidateScreen> createState() =>
      _AddEditCandidateScreenState();
}

class _AddEditCandidateScreenState
    extends State<AddEditCandidateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CandidateService();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  int stage = 1;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.candidate != null) {
      nameCtrl.text = widget.candidate!.fullName;
      phoneCtrl.text = widget.candidate!.phone;
      emailCtrl.text = widget.candidate!.email;
      notesCtrl.text = widget.candidate!.notes ?? '';
      stage = widget.candidate!.stage;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  // ================= SAVE =================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final data = {
        "id": widget.candidate?.id,
        "fullName": nameCtrl.text.trim(),
        "phone": phoneCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "stage": stage,
        "notes": notesCtrl.text.trim(),
        "isActive": true,
      };

      await _service.saveCandidate(data);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _show("Save failed");
    }

    setState(() => saving = false);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.candidate != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Candidate" : "Add Candidate"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field("Full Name", nameCtrl),
            _field("Mobile", phoneCtrl,
                keyboard: TextInputType.phone),
            _field("Email", emailCtrl,
                keyboard: TextInputType.emailAddress),

            _stageDropdown(),

            _field("Notes", notesCtrl, maxLines: 3),

            const SizedBox(height: 20),

            saving
                ? const Center(
                    child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _save,
                    child: const Text("Save"),
                  ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (v) =>
            v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _stageDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        initialValue: stage,
        decoration: const InputDecoration(
          labelText: "Stage",
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 1, child: Text("Applied")),
          DropdownMenuItem(value: 2, child: Text("Interview")),
          DropdownMenuItem(value: 3, child: Text("Selected")),
        ],
        onChanged: (v) => setState(() => stage = v!),
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
