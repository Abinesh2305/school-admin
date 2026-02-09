import 'package:flutter/material.dart';
import 'academic_service.dart';

class ClassSectionGridScreen extends StatefulWidget {
  const ClassSectionGridScreen({super.key});

  @override
  State<ClassSectionGridScreen> createState() => _ClassSectionGridScreenState();
}

class _ClassSectionGridScreenState extends State<ClassSectionGridScreen> {
  bool loading = true;

  List classes = [];

  static const Color teal = Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /* ================= LOAD ================= */

  Future<void> _loadData() async {
    try {
      setState(() => loading = true);

      final res = await AcademicService.getClasses();

      final List items = res['items'];

      for (var cls in items) {
        final secRes = await AcademicService.getSections(classId: cls['id']);

        cls['sections'] = secRes['items'];
      }

      setState(() {
        classes = items;
        loading = false;
      });
    } catch (e) {
      loading = false;
      _error(e.toString());
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      /* ================= APP BAR ================= */
      appBar: AppBar(
        backgroundColor: teal,
        elevation: 1,
        title: const Text(
          'Class & Section Manager',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: screenWidth < 600,

        actions: [
          // ADD CLASS
          Tooltip(
            message: 'Add New Class',
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              onPressed: _openAddClass,
              splashRadius: 24,
            ),
          ),

          // REFRESH
          Tooltip(
            message: 'Refresh Data',
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              onPressed: _loadData,
              splashRadius: 24,
            ),
          ),
          SizedBox(width: screenWidth < 600 ? 0 : 8),
        ],
      ),

      /* ================= BODY ================= */
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: teal),
                  const SizedBox(height: 16),
                  const Text('Loading classes...'),
                ],
              ),
            )
          : _buildGrid(),
    );
  }

  /* ================= GRID ================= */

  Widget _buildGrid() {
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Classes Found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openAddClass,
              style: ElevatedButton.styleFrom(backgroundColor: teal),
              icon: const Icon(Icons.add),
              label: const Text('Create First Class'),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final padding = isMobile
        ? 10.0
        : isTablet
        ? 12.0
        : 16.0;
    final spacing = isMobile
        ? 10.0
        : isTablet
        ? 12.0
        : 16.0;

    return RefreshIndicator(
      color: teal,
      onRefresh: _loadData,

      child: GridView.builder(
        padding: EdgeInsets.all(padding),

        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isMobile
              ? 400
              : isTablet
              ? 380
              : 360,
          childAspectRatio: isMobile ? 0.73 : 0.78,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),

        itemCount: classes.length,

        itemBuilder: (_, i) {
          return _classCard(classes[i]);
        },
      ),
    );
  }

  /* ================= CLASS CARD ================= */

  Widget _classCard(dynamic cls) {
    final List sections = cls['sections'] ?? [];
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 14),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /* ================= HEADER ================= */
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          cls['name'],
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Level ${cls['sortOrder']}',
                            style: TextStyle(
                              color: teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${sections.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: teal,
                          ),
                        ),
                        Text(
                          'Sections',
                          style: TextStyle(fontSize: 10, color: teal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Divider(color: Colors.grey.shade200, height: 1),

              /* ================= SECTION LIST ================= */
              Expanded(
                child: sections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 32,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No Sections',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: sections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          return _sectionTile(cls, sections[i], i);
                        },
                      ),
              ),

              /* ================= ADD SECTION ================= */
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: isMobile ? 40 : 44,

                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: teal.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),

                  onPressed: () => _openAddSection(cls),

                  icon: Icon(
                    Icons.add_circle_outline,
                    size: isMobile ? 18 : 20,
                  ),

                  label: Text(
                    'Add Section',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ================= SECTION TILE ================= */

  Widget _sectionTile(dynamic cls, dynamic section, int index) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openEditSection(cls, section),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 8 : 10,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 16 : 18,
                  backgroundColor: teal,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 12),
                Expanded(
                  child: Text(
                    section['name'],
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: isMobile ? 16 : 18,
                        ),
                        color: teal,
                        padding: EdgeInsets.all(isMobile ? 4 : 6),
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 28 : 32,
                          minHeight: isMobile ? 28 : 32,
                        ),
                        onPressed: () => _openEditSection(cls, section),
                      ),
                    ),
                    SizedBox(width: isMobile ? 2 : 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: isMobile ? 16 : 18,
                        ),
                        color: Colors.red,
                        padding: EdgeInsets.all(isMobile ? 4 : 6),
                        constraints: BoxConstraints(
                          minWidth: isMobile ? 28 : 32,
                          minHeight: isMobile ? 28 : 32,
                        ),
                        onPressed: () => _deleteSection(cls, section),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ================= ADD CLASS ================= */

  void _openAddClass() {
    final nameCtrl = TextEditingController();
    final orderCtrl = TextEditingController();

    _commonDialog(
      title: 'Add Class',
      nameCtrl: nameCtrl,
      orderCtrl: orderCtrl,

      onSave: () async {
        final name = nameCtrl.text.trim();
        final order = int.tryParse(orderCtrl.text);

        if (name.isEmpty || order == null) {
          _error('Invalid input');
          return;
        }

        await _createClass(name, order);

        Navigator.pop(context);
      },
    );
  }

  /* ================= ADD / EDIT SECTION ================= */

  void _openAddSection(dynamic cls) {
    _openSectionDialog(title: 'Add Section', cls: cls);
  }

  void _openEditSection(dynamic cls, dynamic section) {
    _openSectionDialog(title: 'Edit Section', cls: cls, section: section);
  }

  /* ================= CLASS API ================= */

  Future<void> _createClass(String name, int order) async {
    try {
      await AcademicService.createClass(name: name, sortOrder: order);

      await _loadData();

      _success('Class Added');
    } catch (e) {
      _error(e.toString());
    }
  }

  /* ================= SECTION DIALOG ================= */

  void _openSectionDialog({
    required String title,
    required dynamic cls,
    dynamic section,
  }) {
    final nameCtrl = TextEditingController(text: section?['name'] ?? '');

    final orderCtrl = TextEditingController(
      text: section?['sortOrder']?.toString() ?? '',
    );

    _commonDialog(
      title: title,
      nameCtrl: nameCtrl,
      orderCtrl: orderCtrl,

      onSave: () async {
        final name = nameCtrl.text.trim();
        final order = int.tryParse(orderCtrl.text);

        if (name.isEmpty || order == null) {
          _error('Invalid input');
          return;
        }

        try {
          if (section == null) {
            await AcademicService.createSection(
              classId: cls['id'],
              name: name,
              sortOrder: order,
            );

            _success('Section Added');
          } else {
            await AcademicService.updateSection(
              classId: cls['id'],
              sectionId: section['id'],
              name: name,
              sortOrder: order,
            );

            _success('Section Updated');
          }

          await _loadData();

          Navigator.pop(context);
        } catch (e) {
          _error(e.toString());
        }
      },
    );
  }

  /* ================= COMMON DIALOG ================= */

  void _commonDialog({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController orderCtrl,
    required VoidCallback onSave,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.text_fields, color: teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF009688),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Order / Level',
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(Icons.numbers, color: teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF009688),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: onSave,
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /* ================= DELETE ================= */

  Future<void> _deleteSection(dynamic cls, dynamic section) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Section',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete "${section['name']}"?\nThis action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          try {
                            await AcademicService.deleteSection(
                              classId: cls['id'],
                              sectionId: section['id'],
                            );

                            await _loadData();

                            _success('Section deleted successfully');
                          } catch (e) {
                            _error(e.toString());
                          }
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /* ================= HELPERS ================= */

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _success(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
