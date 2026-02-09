import 'package:flutter/material.dart';
import 'academic_service.dart';

class SubjectMasterScreen extends StatefulWidget {
  const SubjectMasterScreen({super.key});

  @override
  State<SubjectMasterScreen> createState() => _SubjectMasterScreenState();
}

class _SubjectMasterScreenState extends State<SubjectMasterScreen> {
  final searchCtrl = TextEditingController();

  bool loading = false;

  List<Map<String, dynamic>> subjects = [];

  /// subjectId -> mappings
  Map<int, List<dynamic>> subjectMappings = {};

  @override
  void initState() {
    super.initState();

    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadSubjects();
    await _loadMappings();
  }

  /* ================= LOAD SUBJECTS ================= */

  Future<void> _loadSubjects() async {
    setState(() => loading = true);

    try {
      final res = await AcademicService.getSubjects();

      final List items = res['items'] ?? [];

      subjects = items.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _show("Failed to load subjects");
    }

    setState(() => loading = false);
  }

  /* ================= LOAD MAPPINGS ================= */

  Future<void> _loadMappings() async {
  try {
    final res =
        await AcademicService.getSectionSubjectMappings();

    final List items = res['items'] ?? [];

    final Map<int, List<dynamic>> map = {};

    for (var m in items) {

      final List subjectIds = m['subjectIds'] ?? [];

      for (var sid in subjectIds) {

        if (sid == null) continue;

        map.putIfAbsent(sid, () => []);
        map[sid]!.add(m);
      }
    }

    setState(() {
      subjectMappings = map;
    });

  } catch (e) {
    debugPrint("MAPPING LOAD ERROR: $e");
  }
}


  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Subject Masters"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
        children: [
          _topBar(),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _subjectList(),
          ),
        ],
      ),
    );
  }

  /* ================= TOP BAR ================= */

  Widget _topBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),

      child: Row(
        children: [
          Expanded(child: _searchField()),

          const SizedBox(width: 12),

          _addButton(),
        ],
      ),
    );
  }

  Widget _searchField() => TextField(
    controller: searchCtrl,
    decoration: const InputDecoration(
      hintText: "Search subject...",
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
      isDense: true,
    ),
    onChanged: (_) => setState(() {}),
  );

  Widget _addButton() => ElevatedButton.icon(
    onPressed: _addSubjectDialog,
    icon: const Icon(Icons.add),
    label: const Text("Add Subject"),
  );

  /* ================= SUBJECT LIST ================= */

  Widget _subjectList() {
    final keyword = searchCtrl.text.toLowerCase();

    final filtered = subjects.where((s) {
      return s['name'].toString().toLowerCase().contains(keyword);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("No Subjects"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (c, i) => _subjectCard(filtered[i]),
    );
  }

  /* ================= SUBJECT CARD ================= */

  Widget _subjectCard(Map<String, dynamic> subject) {
    final id = subject['id'];

    final mappings = subjectMappings[id] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            subject['name'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          Text(
            "Code: ${subject['code']}",
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const Divider(),

          // Mappings
          if (mappings.isEmpty)
            const Text("No Mapping")
          else
            Column(
              children: mappings.map((m) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.link, size: 18),
                  title: Text("Class ${m['className']}"),
                  subtitle: Text("Section ${m['sectionName']}"),
                );
              }).toList(),
            ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text("Map Section"),
              onPressed: () => _mapSubjectDialog(subject),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= MAP DIALOG ================= */

  void _mapSubjectDialog(Map subject) async {
    List<dynamic> classes = [];
    List<dynamic> sections = [];

    int? classId;
    int? sectionId;

    try {
      classes = await AcademicService.getClassDropdown();
    } catch (_) {
      _show("Failed to load classes");
      return;
    }

    showDialog(
      context: context,

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Map - ${subject['name']}"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CLASS
                  DropdownButtonFormField<int>(
                    value: classId,

                    decoration: const InputDecoration(
                      labelText: "Class",
                      border: OutlineInputBorder(),
                    ),

                    items: classes.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name']),
                      );
                    }).toList(),

                    onChanged: (v) async {
                      classId = v;
                      sectionId = null;

                      if (v != null) {
                        final res = await AcademicService.getSections(
                          classId: v,
                        );

                        sections = res['items'] ?? [];
                      }

                      setStateDialog(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  // SECTION
                  DropdownButtonFormField<int>(
                    value: sectionId,

                    decoration: const InputDecoration(
                      labelText: "Section",
                      border: OutlineInputBorder(),
                    ),

                    items: sections.map((s) {
                      return DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text(s['name']),
                      );
                    }).toList(),

                    onChanged: (v) {
                      sectionId = v;
                      setStateDialog(() {});
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  child: const Text("Map"),

                  onPressed: () async {
                    if (classId == null || sectionId == null) {
                      _show("Select Class & Section");
                      return;
                    }

                    try {
                      await AcademicService.applySubjectsToSections(
                        sectionIds: [sectionId!],
                        subjectIds: [subject['id']],
                      );

                      Navigator.pop(context);

                      await _loadMappings();

                      _show("Mapped Successfully");
                    } catch (e) {
                      _show("Mapping Failed");
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ================= ADD SUBJECT ================= */

  void _addSubjectDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text("Add Subject"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: "Code",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              child: const Text("Save"),

              onPressed: () async {
                if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                  _show("Fill all fields");
                  return;
                }

                try {
                  await AcademicService.createSubject(
                    name: nameCtrl.text.trim(),
                    code: codeCtrl.text.trim(),
                    sortOrder: subjects.length,
                  );

                  Navigator.pop(context);

                  await _loadSubjects();

                  _show("Subject Added");
                } catch (e) {
                  _show("Failed");
                }
              },
            ),
          ],
        );
      },
    );
  }

  /* ================= HELPERS ================= */

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          blurRadius: 6,
          color: Colors.black.withOpacity(0.03),
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
