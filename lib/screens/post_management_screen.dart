import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../widgets/rich_text_editor.dart';
import '../services/notification_service.dart';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';
import 'crop_your_image.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});

  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;
  final NotificationService _notificationService = NotificationService();
  late RichTextEditorController _richTextController;

  @override
  void initState() {
    super.initState();
    _richTextController = RichTextEditorController();
    _loadPosts();
  }

  @override
  void dispose() {
    _richTextController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final posts = await _notificationService.getPostCommunications(
        type: 'post',
      );
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    }
  }

  Future<void> _createPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostFormScreen(richTextController: _richTextController),
      ),
    );
    if (result == true) {
      _loadPosts();
    }
  }

  Future<void> _editPost(dynamic post) async {
    final controller = RichTextEditorController(
      initialText: post['message'] ?? '',
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PostFormScreen(post: post, richTextController: controller),
      ),
    );
    controller.dispose();
    if (result == true) {
      _loadPosts();
    }
  }

  Future<void> _deletePost(dynamic post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
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
          'admin/communication/${post['id']}',
          options: Options(headers: {'x-api-key': token}),
          data: {'user_id': user['id'], 'api_token': token},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
          _loadPosts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
        }
      }
    }
  }

  Future<void> _approvePost(dynamic post) async {
    try {
      final box = Hive.box('settings');
      final token = box.get('token');
      final user = box.get('user');

      await DioClient.dio.post(
        'admin/communication/${post['id']}/approve',
        options: Options(headers: {'x-api-key': token}),
        data: {'user_id': user['id'], 'api_token': token},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post approved successfully')),
        );
        _loadPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving post: $e')));
      }
    }
  }

  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredPosts = _getFilteredPosts();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Posts for Scholars',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: colorScheme.onSurface),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: colorScheme.onSurface),
                    onPressed: _loadPosts,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createPost,
                    icon: Icon(Icons.add, color: colorScheme.onPrimary),
                    label: Text(
                      'Create',
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.filter_list, color: colorScheme.onSurface),
                    onPressed: () {
                      // TODO: Show filter options
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', _selectedFilter == 'all'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Un Approved',
                  _selectedFilter == 'unapproved',
                ),
                const SizedBox(width: 8),
                _buildFilterChip('Link', _selectedFilter == 'link'),
                const SizedBox(width: 8),
                _buildFilterChip('SMS', _selectedFilter == 'sms'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Posts List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filteredPosts.isEmpty
                ? const Center(child: Text('No posts found'))
                : ListView.builder(
                    itemCount: filteredPosts.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return _buildPostCard(post, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getFilteredPosts() {
    var posts = _posts;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      posts = posts.where((post) {
        final title = (post['title'] ?? '').toString().toLowerCase();
        final message = (post['message'] ?? '').toString().toLowerCase();
        return title.contains(searchLower) || message.contains(searchLower);
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter == 'unapproved') {
      posts = posts.where((post) => post['status'] != 'approved').toList();
    } else if (_selectedFilter == 'link') {
      posts = posts.where((post) => post['type'] == 'link').toList();
    } else if (_selectedFilter == 'sms') {
      posts = posts.where((post) => post['type'] == 'sms').toList();
    }

    return posts;
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(
        () => _selectedFilter = label.toLowerCase().replaceAll(' ', '_'),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(dynamic post, ColorScheme colorScheme) {
    final postType = post['type'] ?? 'post';
    final postDate = post['created_at'] ?? post['date'] ?? '';
    final schoolName = post['school_name'] ?? 'CPL Demo School';
    final postFor = post['post_for'] ?? 'All';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'To: $postFor',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$postType • ${_formatPostDate(postDate)}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
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
                        _editPost(post);
                        break;
                      case 'delete':
                        _deletePost(post);
                        break;
                      case 'approve':
                        _approvePost(post);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),

          // Content Area
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.8),
                  colorScheme.secondaryContainer.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (postType == 'link')
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      'LINK',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  post['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stripHtmlTags(post['message'] ?? ''),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPostDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = date.day;
      final month = months[date.month - 1];
      final year = date.year;
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$day $month, $year $displayHour:$minute $period';
    } catch (_) {
      return dateStr;
    }
  }

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class PostFormScreen extends StatefulWidget {
  final dynamic post;
  final RichTextEditorController richTextController;

  const PostFormScreen({
    super.key,
    this.post,
    required this.richTextController,
  });

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  bool _loading = false;
  String? _selectedCategory;
  String _postFor =
      'all_scholars'; // 'all_scholars', 'class_sections', 'specific_scholars', 'group'
  bool _ccStaffs = false;
  List<int> _selectedStaffIds = [];
  bool _requiresAck = false;
  bool _sendLater = false;
  DateTime? _scheduledDate;
  dynamic _attachedFilesRaw;
  List<File> get _attachedFiles {
    if (_attachedFilesRaw == null) {
      _attachedFilesRaw = <File>[];
      return _attachedFilesRaw;
    }
    if (_attachedFilesRaw is List<File>) {
      return _attachedFilesRaw;
    }
    // Handle type mismatch from hot reload - convert to proper type
    if (_attachedFilesRaw is List) {
      _attachedFilesRaw = (_attachedFilesRaw as List)
          .map((item) => item is File ? item : File(item.toString()))
          .whereType<File>()
          .toList();
      return _attachedFilesRaw;
    }
    _attachedFilesRaw = <File>[];
    return _attachedFilesRaw;
  }

  dynamic _attachedFileNamesRaw;
  List<String> get _attachedFileNames {
    if (_attachedFileNamesRaw == null) {
      _attachedFileNamesRaw = <String>[];
      return _attachedFileNamesRaw;
    }
    if (_attachedFileNamesRaw is List<String>) {
      return _attachedFileNamesRaw;
    }
    // Handle type mismatch from hot reload
    if (_attachedFileNamesRaw is List) {
      _attachedFileNamesRaw = (_attachedFileNamesRaw as List)
          .map((item) => item.toString())
          .toList();
      return _attachedFileNamesRaw;
    }
    _attachedFileNamesRaw = <String>[];
    return _attachedFileNamesRaw;
  }

  int _characterCount = 0;
  List<dynamic> _categories = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize the raw variables
    _speech = stt.SpeechToText();
    _attachedFilesRaw = <File>[];
    _attachedFileNamesRaw = <String>[];

    if (widget.post != null) {
      _titleController.text = widget.post['title'] ?? '';
      _selectedCategory = widget.post['category_id']?.toString();
      _postFor = widget.post['post_for'] ?? 'all_scholars';
      _ccStaffs = widget.post['cc_staffs'] == 1;
      _selectedStaffIds = List<int>.from(widget.post['cc_staff_ids'] ?? []);
      _requiresAck = widget.post['ack_required'] == 1;
      _sendLater = widget.post['scheduled_date'] != null;
      if (_sendLater) {
        try {
          _scheduledDate = DateTime.parse(widget.post['scheduled_date']);
        } catch (_) {}
      }
      widget.richTextController.setText(widget.post['message'] ?? '');
    }
    _loadCategories();
    _updateCharacterCount();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
    }

    return false;
  }

  Future<void> _toggleListeningTamil() async {
    final hasPermission = await _requestMicPermission();
    if (!hasPermission) return;

    if (!_isListening) {
      final available = await _speech.initialize(debugLogging: false);

      if (!available) return;

      setState(() => _isListening = true);

      _speech.listen(
        localeId: 'ta-IN', // 🇮🇳 Tamil
        listenMode: stt.ListenMode.dictation,
        onResult: (result) async {
          if (result.recognizedWords.isEmpty) return;

          final currentHtml = await widget.richTextController.htmlText;

          final updatedText = currentHtml.trim().isEmpty
              ? result.recognizedWords
              : '$currentHtml ${result.recognizedWords}';

          widget.richTextController.setText(updatedText);
          _updateCharacterCount();
        },
      );
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final box = Hive.box('settings');
      final token = box.get('token');

      final response = await DioClient.dio.get(
        'admin/categories',
        options: Options(headers: {'x-api-key': token}),
      );

      if (response.statusCode == 200 && response.data['status'] == 1) {
        setState(() {
          _categories = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _updateCharacterCount() async {
    final text = await widget.richTextController.plainText;
    setState(() {
      _characterCount = text.length;
    });
  }

  bool _isImage(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif');
  }

  Future<File?> _openCropScreen(File file) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => CropYourImageScreen(imageFile: file)),
    );
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    int quality = 75;
    File output = file;

    for (int i = 0; i < 5; i++) {
      final targetPath =
          '${dir.path}/post_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        output.path,
        targetPath,
        quality: quality,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );

      if (result == null) break;

      output = File(result.path);

      if (output.lengthSync() / 1024 <= 500) break;

      quality -= 10;
      if (quality < 30) break;
    }

    return output;
  }

  Future<void> _pickFiles() async {
    if (_loading) return;

    try {
      // Show options: Image, File, or Camera
      final option = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Pick Image'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Pick File'),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

      if (option == null) return;

      File? selectedFile;

      if (option == 'image') {
        // Pick image from gallery
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              File file = File(platformFile.path!);
              // Crop and compress if it's an image
              final cropped = await _openCropScreen(file);
              if (cropped != null) {
                final compressed = await _compressImage(cropped);
                setState(() {
                  _attachedFilesRaw = List<File>.from(_attachedFiles)
                    ..add(compressed);
                  _attachedFileNamesRaw = List<String>.from(_attachedFileNames)
                    ..add(platformFile.name);
                });
              }
            }
          }
        }
      } else if (option == 'camera') {
        // Take photo with camera
        final photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 90,
        );

        if (photo != null) {
          File file = File(photo.path);
          final cropped = await _openCropScreen(file);
          if (cropped != null) {
            final compressed = await _compressImage(cropped);
            setState(() {
              _attachedFilesRaw = List<File>.from(_attachedFiles)
                ..add(compressed);
              _attachedFileNamesRaw = List<String>.from(_attachedFileNames)
                ..add('camera_${DateTime.now().millisecondsSinceEpoch}.jpg');
            });
          }
        }
      } else if (option == 'file') {
        // Pick any file
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'ppt',
            'pptx',
            'txt',
            'zip',
            'rar',
          ],
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              File file = File(platformFile.path!);
              setState(() {
                _attachedFilesRaw = List<File>.from(_attachedFiles)..add(file);
                _attachedFileNamesRaw = List<String>.from(_attachedFileNames)
                  ..add(platformFile.name);
              });
            }
          }
        }
      }

      if (mounted && _attachedFiles.isNotEmpty) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_attachedFiles.length} file(s) added'),
            backgroundColor: cs.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: cs.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final box = Hive.box('settings');
      final token = box.get('token');
      final user = box.get('user');
      final message = await widget.richTextController.htmlText;

      // Prepare form data for file upload
      final formData = FormData.fromMap({
        'user_id': user['id'],
        'api_token': token,
        'title': _titleController.text.trim(),
        'message': message,
        'type': 1, // Post type
        'category_id': _selectedCategory,
        'post_for': _postFor,
        'cc_staffs': _ccStaffs ? 1 : 0,
        'cc_staff_ids': _selectedStaffIds,
        'ack_required': _requiresAck ? 1 : 0,
        if (_sendLater && _scheduledDate != null)
          'scheduled_date': _scheduledDate!.toIso8601String(),
      });

      // Add files to form data
      final files = _attachedFiles;
      final fileNames = _attachedFileNames;
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = fileNames[i];
        formData.files.add(
          MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      if (widget.post != null) {
        // Update existing post
        await DioClient.dio.put(
          'admin/communication/${widget.post['id']}',
          options: Options(
            headers: {'x-api-key': token},
            contentType: 'multipart/form-data',
          ),
          data: formData,
        );
      } else {
        // Create new post
        await DioClient.dio.post(
          'admin/communication',
          options: Options(
            headers: {'x-api-key': token},
            contentType: 'multipart/form-data',
          ),
          data: formData,
        );
      }

      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.post != null
                  ? 'Post updated successfully'
                  : 'Post created successfully',
            ),
            backgroundColor: cs.primaryContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving post: $e'),
            backgroundColor: cs.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectStaffs() async {
    // TODO: Implement staff selection screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff selection will be implemented')),
    );
  }

  Future<void> _selectClassSections() async {
    // TODO: Implement class & section selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Class & Section selection will be implemented'),
      ),
    );
  }

  Future<void> _selectSpecificScholars() async {
    // TODO: Implement specific scholars selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scholar selection will be implemented')),
    );
  }

  Future<void> _selectGroup() async {
    // TODO: Implement group selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group selection will be implemented')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.post != null ? 'Edit Post' : 'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message Field
            // Message Field + 🎤 Tamil Speech
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Message',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleListeningTamil,
                ),
              ],
            ),
            const SizedBox(height: 8),

            RichTextEditor(
              controller: widget.richTextController.controller,
              hint: 'Message',
              height: 350,
              enableImageUpload: true,
              enableFileUpload: true,
              onChanged: (_) => _updateCharacterCount(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_characterCount characters',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Field
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                hintText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface,
                ),
              ),
              style: TextStyle(color: colorScheme.onSurface),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat['id'].toString(),
                  child: Text(cat['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 24),

            // Post For Section
            Text(
              'Post For:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildPostForChip(
                  'All Scholars',
                  _postFor == 'all_scholars',
                  Icons.check,
                  () => setState(() => _postFor = 'all_scholars'),
                ),
                _buildPostForChip(
                  'Class & Sections',
                  _postFor == 'class_sections',
                  null,
                  () {
                    setState(() => _postFor = 'class_sections');
                    _selectClassSections();
                  },
                ),
                _buildPostForChip(
                  'Specific Scholars',
                  _postFor == 'specific_scholars',
                  null,
                  () {
                    setState(() => _postFor = 'specific_scholars');
                    _selectSpecificScholars();
                  },
                ),
                _buildPostForChip('Group', _postFor == 'group', null, () {
                  setState(() => _postFor = 'group');
                  _selectGroup();
                }),
              ],
            ),
            const SizedBox(height: 24),

            // CC Staffs Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Also send to CC Staffs',
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
                TextButton(
                  onPressed: _ccStaffs ? _selectStaffs : null,
                  child: Text(
                    'Select Staffs',
                    style: TextStyle(
                      color: _ccStaffs
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Request Acknowledgment Checkbox
            Row(
              children: [
                Checkbox(
                  value: _requiresAck,
                  onChanged: (value) {
                    setState(() => _requiresAck = value ?? false);
                  },
                  activeColor: colorScheme.primary,
                ),
                Text(
                  'Request Acknowledgment',
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Send Later Checkbox
            Row(
              children: [
                Checkbox(
                  value: _sendLater,
                  onChanged: (value) {
                    setState(() {
                      _sendLater = value ?? false;
                      if (_sendLater && _scheduledDate == null) {
                        _selectDate();
                      }
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                Text(
                  'Send Later',
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preview Section
            Text(
              'Preview:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Center(
                child: Text(
                  'Preview will appear here',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _savePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPostForChip(
    String label,
    bool isSelected,
    IconData? icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && isSelected) ...[
              Icon(icon, size: 18, color: colorScheme.onPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
