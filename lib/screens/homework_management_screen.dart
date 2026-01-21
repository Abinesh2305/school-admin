import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/rich_text_editor.dart';
import '../services/homework_service.dart';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';

class HomeworkManagementScreen extends StatefulWidget {
  const HomeworkManagementScreen({super.key});

  @override
  State<HomeworkManagementScreen> createState() => _HomeworkManagementScreenState();
}

class _HomeworkManagementScreenState extends State<HomeworkManagementScreen> {
  List<dynamic> _homeworks = [];
  bool _loading = true;
  final HomeworkService _homeworkService = HomeworkService();

  @override
  void initState() {
    super.initState();
    _loadHomeworks();
  }

  Future<void> _loadHomeworks() async {
    setState(() => _loading = true);
    try {
      final homeworks = await _homeworkService.getHomeworks();
      setState(() {
        _homeworks = homeworks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading homeworks: $e')),
        );
      }
    }
  }

  Future<void> _createHomework() async {
    final controller = RichTextEditorController();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkFormScreen(
          richTextController: controller,
        ),
      ),
    );
    controller.dispose();
    if (result == true) {
      _loadHomeworks();
    }
  }

  Future<void> _editHomework(dynamic homework) async {
    final controller = RichTextEditorController(
      initialText: homework['homework'] ?? '',
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkFormScreen(
          homework: homework,
          richTextController: controller,
        ),
      ),
    );
    controller.dispose();
    if (result == true) {
      _loadHomeworks();
    }
  }

  Future<void> _deleteHomework(dynamic homework) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Homework'),
        content: const Text('Are you sure you want to delete this homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final box = Hive.box('settings');
        final token = box.get('token');
        final user = box.get('user');

        await DioClient.dio.delete(
          'admin/homework/${homework['id']}',
          options: Options(
            headers: {'x-api-key': token},
          ),
          data: {
            'user_id': user['id'],
            'api_token': token,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Homework deleted successfully')),
          );
          _loadHomeworks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting homework: $e')),
          );
        }
      }
    }
  }

  Future<void> _approveHomework(dynamic homework) async {
    try {
      final box = Hive.box('settings');
      final token = box.get('token');
      final user = box.get('user');

      await DioClient.dio.post(
        'admin/homework/${homework['id']}/approve',
        options: Options(
          headers: {'x-api-key': token},
        ),
        data: {
          'user_id': user['id'],
          'api_token': token,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homework approved successfully')),
        );
        _loadHomeworks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving homework: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Management'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Homeworks (${_homeworks.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _createHomework,
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _homeworks.isEmpty
                      ? const Center(child: Text('No homeworks found'))
                      : ListView.builder(
                          itemCount: _homeworks.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final homework = _homeworks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  homework['subject'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subject: ${homework['subject'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      homework['description']?.toString().substring(
                                            0,
                                            (homework['description']?.toString().length ?? 0) > 50
                                                ? 50
                                                : (homework['description']?.toString().length ?? 0),
                                          ) ??
                                          '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                    if (homework['status'] != 'approved')
                                      const PopupMenuItem(
                                        value: 'approve',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, size: 20),
                                            SizedBox(width: 8),
                                            Text('Approve'),
                                          ],
                                        ),
                                      ),
                                  ],
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editHomework(homework);
                                        break;
                                      case 'delete':
                                        _deleteHomework(homework);
                                        break;
                                      case 'approve':
                                        _approveHomework(homework);
                                        break;
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class HomeworkFormScreen extends StatefulWidget {
  final dynamic homework;
  final RichTextEditorController richTextController;

  const HomeworkFormScreen({
    super.key,
    this.homework,
    required this.richTextController,
  });

  @override
  State<HomeworkFormScreen> createState() => _HomeworkFormScreenState();
}

class _HomeworkFormScreenState extends State<HomeworkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.homework != null) {
      _subjectController.text = widget.homework['subject'] ?? '';
      _classController.text = widget.homework['class_name'] ?? '';
      widget.richTextController.setText(widget.homework['description'] ?? '');
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _saveHomework() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final box = Hive.box('settings');
      final token = box.get('token');
      final user = box.get('user');
      final homeworkText = await widget.richTextController.plainText;

      final data = {
        'user_id': user['id'],
        'api_token': token,
        'subject': _subjectController.text,
        'class_name': _classController.text,
        'description': homeworkText,
        'date': DateTime.now().toIso8601String().split('T')[0],
      };

      if (widget.homework != null) {
        // Update existing homework
        await DioClient.dio.put(
          'admin/homework/${widget.homework['id']}',
          options: Options(
            headers: {'x-api-key': token},
          ),
          data: data,
        );
      } else {
        // Create new homework
        await DioClient.dio.post(
          'admin/homework',
          options: Options(
            headers: {'x-api-key': token},
          ),
          data: data,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.homework != null
                ? 'Homework updated successfully'
                : 'Homework created successfully'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving homework: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.homework != null ? 'Edit Homework' : 'Create Homework'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveHomework,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _classController,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a class';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            RichTextEditor(
              controller: widget.richTextController.controller,
              label: 'Homework',
              hint: 'Enter homework details...',
              height: 300,
            ),
          ],
        ),
      ),
    );
  }
}

