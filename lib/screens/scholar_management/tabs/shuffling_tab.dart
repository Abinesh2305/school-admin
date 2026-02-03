import 'package:flutter/material.dart';

const Color kTeal = Color(0xFF009688);

class ScholarShufflingScreen extends StatefulWidget {
  const ScholarShufflingScreen({super.key});

  @override
  State<ScholarShufflingScreen> createState() => _ScholarShufflingScreenState();
}

class _ScholarShufflingScreenState extends State<ScholarShufflingScreen> {
  String? fromClass, fromSection;
  String? toClass, toSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= BODY =================
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _moveCard(
                  title: 'Move Scholars From',
                  classValue: fromClass,
                  sectionValue: fromSection,
                  onClassChanged: (v) => setState(() {
                    fromClass = v;
                    fromSection = null;
                  }),
                  onSectionChanged: (v) => setState(() => fromSection = v),
                ),
                const SizedBox(height: 16),
                _moveCard(
                  title: 'Move Scholars To',
                  classValue: toClass,
                  sectionValue: toSection,
                  onClassChanged: (v) => setState(() {
                    toClass = v;
                    toSection = null;
                  }),
                  onSectionChanged: (v) => setState(() => toSection = v),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: Row(
                    children: const [
                      Expanded(
                        child: _EmptyPanel(
                          text: 'Select From Class and Section',
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _EmptyPanel(
                          text: 'Select To Class and Section',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ================= BOTTOM BAR =================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(
            children: [
              Chip(
                label: const Text('Selected: 0'),
                backgroundColor: kTeal.withOpacity(0.15),
                labelStyle: const TextStyle(color: kTeal),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: null, // enable later
                icon: const Icon(Icons.drive_file_move),
                label: const Text('Confirm Move'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  disabledBackgroundColor: Colors.grey.shade400,
                  minimumSize: const Size(160, 38),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* ================= MOVE CARD ================= */

  Widget _moveCard({
    required String title,
    required String? classValue,
    required String? sectionValue,
    required ValueChanged<String?> onClassChanged,
    required ValueChanged<String?> onSectionChanged,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: kTeal.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTeal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: classValue,
                    decoration: _inputDecoration('Class'),
                    items: ['I', 'II', 'III']
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: onClassChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: sectionValue,
                    decoration:
                        _inputDecoration('Section (pick class first)'),
                    items: classValue == null
                        ? const []
                        : ['A', 'B', 'C']
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                    onChanged: classValue == null ? null : onSectionChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kTeal, width: 1.5),
      ),
    );
  }
}

/* ================= EMPTY PANEL ================= */

class _EmptyPanel extends StatelessWidget {
  final String text;
  const _EmptyPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kTeal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kTeal.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
