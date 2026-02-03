import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/rich_text_editor.dart';
import '../services/notification_service.dart';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';

class StaffPostsManagementScreen extends StatefulWidget {
  const StaffPostsManagementScreen({super.key});

  @override
  State<StaffPostsManagementScreen> createState() =>
      _StaffPostsManagementScreenState();
}

class _StaffPostsManagementScreenState
    extends State<StaffPostsManagementScreen> {
  List<dynamic> _staffPosts = [];
  bool _loading = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadStaffPosts();
  }

  Future<void> _loadStaffPosts() async {
    setState(() => _loading = true);
    try {
      // Filter for staff posts - you may need to adjust this based on your API
      final posts = await _notificationService.getPostCommunications();
      setState(() {
        // Filter posts that are from staff or have staff_post flag
        _staffPosts = posts
            .where(
              (post) =>
                  post['type'] == 'staff_post' ||
                  post['created_by_type'] == 'staff',
            )
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading staff posts: $e')),
        );
      }
    }
  }

  Future<void> _createStaffPost() async {
    final controller = RichTextEditorController();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffPostFormScreen(richTextController: controller),
      ),
    );
    controller.dispose();
    if (result == true) {
      _loadStaffPosts();
    }
  }

  Future<void> _editStaffPost(dynamic post) async {
    final controller = RichTextEditorController(
      initialText: post['message'] ?? '',
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StaffPostFormScreen(post: post, richTextController: controller),
      ),
    );
    controller.dispose();
    if (result == true) {
      _loadStaffPosts();
    }
  }

  Future<void> _deleteStaffPost(dynamic post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Post'),
        content: const Text('Are you sure you want to delete this staff post?'),
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
          'admin/staff-post/${post['id']}',
          options: Options(headers: {'x-api-key': token}),
          data: {'user_id': user['id'], 'api_token': token},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff post deleted successfully')),
          );
          _loadStaffPosts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting staff post: $e')),
          );
        }
      }
    }
  }

  Future<void> _approveStaffPost(dynamic post) async {
    try {
      final box = Hive.box('settings');
      final token = box.get('token');
      final user = box.get('user');

      await DioClient.dio.post(
        'admin/staff-post/${post['id']}/approve',
        options: Options(headers: {'x-api-key': token}),
        data: {'user_id': user['id'], 'api_token': token},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff post approved successfully')),
        );
        _loadStaffPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving staff post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Posts Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Staff Posts (${_staffPosts.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ElevatedButton.icon(
                        onPressed: _createStaffPost,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Staff Post'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _staffPosts.isEmpty
                      ? const Center(child: Text('No staff posts found'))
                      : ListView.builder(
                          itemCount: _staffPosts.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final post = _staffPosts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  post['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'By: ${post['created_by_name'] ?? 'Staff'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      post['message']?.toString().substring(
                                            0,
                                            (post['message']
                                                            ?.toString()
                                                            .length ??
                                                        0) >
                                                    50
                                                ? 50
                                                : (post['message']
                                                          ?.toString()
                                                          .length ??
                                                      0),
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
                                    if (post['status'] != 'approved')
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
                                        _editStaffPost(post);
                                        break;
                                      case 'delete':
                                        _deleteStaffPost(post);
                                        break;
                                      case 'approve':
                                        _approveStaffPost(post);
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

class StaffPostFormScreen extends StatefulWidget {
  final dynamic post;
  final RichTextEditorController richTextController;

  const StaffPostFormScreen({
    super.key,
    this.post,
    required this.richTextController,
  });

  @override
  State<StaffPostFormScreen> createState() => _StaffPostFormScreenState();
}

class _StaffPostFormScreenState extends State<StaffPostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post['title'] ?? '';
      widget.richTextController.setText(widget.post['message'] ?? '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveStaffPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final box = Hive.box('settings');
      final token = box.get('token');
      final user = box.get('user');
      final message = await widget.richTextController.plainText;

      final data = {
        'user_id': user['id'],
        'api_token': token,
        'title': _titleController.text,
        'message': message,
        'type': 'staff_post',
      };

      if (widget.post != null) {
        // Update existing staff post
        await DioClient.dio.put(
          'admin/staff-post/${widget.post['id']}',
          options: Options(headers: {'x-api-key': token}),
          data: data,
        );
      } else {
        // Create new staff post
        await DioClient.dio.post(
          'admin/staff-post',
          options: Options(headers: {'x-api-key': token}),
          data: data,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.post != null
                  ? 'Staff post updated successfully'
                  : 'Staff post created successfully',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving staff post: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post != null ? 'Edit Staff Post' : 'Create Staff Post',
        ),
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
            IconButton(icon: const Icon(Icons.save), onPressed: _saveStaffPost),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            RichTextEditor(
              controller: widget.richTextController.controller,
              label: 'Message',
              hint: 'Enter your staff post message...',
              height: 300,
            ),
          ],
        ),
      ),
    );
  }
}
