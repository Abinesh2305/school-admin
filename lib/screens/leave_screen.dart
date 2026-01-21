import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import '../services/leave_service.dart';
import '../l10n/app_localizations.dart';
import 'crop_your_image.dart';
import '../widgets/rich_text_editor.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late final RichTextEditorController _richTextController;
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();

  String _leaveType = 'FULL DAY'; // unchanged
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  String? _audioPath;
  File? _imageFile;
  File? _documentFile;
  String? _attachmentType; // 'audio', 'image', 'document'
  
  bool _recording = false;
  bool _playing = false;
  bool _loading = false;
  double _currentAmplitude = 0.0;

  List<dynamic> _pendingLeaves = [];
  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    _richTextController = RichTextEditorController();
    settingsBox = Hive.box('settings');
    _loadUnapprovedLeaves();

    settingsBox.watch(key: 'user').listen((event) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _loadUnapprovedLeaves();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _richTextController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadUnapprovedLeaves() async {
    setState(() => _loading = true);

    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) return _loadUnapprovedLeaves();
    }

    final res = await LeaveService().getUnapprovedLeaves();
    if (res != null && res['status'] == 1) {
      setState(() => _pendingLeaves = res['data']);
    } else {
      setState(() => _pendingLeaves = []);
    }

    setState(() => _loading = false);
  }

  Future<void> _applyLeave() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final leaveStart = DateFormat('yyyy-MM-dd').format(_fromDate);
    final leaveEnd = _leaveType == 'MORE THAN ONE DAY'
        ? DateFormat('yyyy-MM-dd').format(_toDate)
        : null;

    // Determine attachment path based on type
    String? attachmentPath;
    if (_attachmentType == 'audio' && _audioPath != null) {
      attachmentPath = _audioPath;
    } else if (_attachmentType == 'image' && _imageFile != null) {
      attachmentPath = _imageFile!.path;
    } else if (_attachmentType == 'document' && _documentFile != null) {
      attachmentPath = _documentFile!.path;
    }

    final richText = await _richTextController.plainText;
    final res = await LeaveService().applyLeave(
      leaveReason: richText.isNotEmpty 
          ? richText 
          : _reasonController.text,
      leaveDate: leaveStart,
      leaveType: _leaveType,
      leaveEndDate: leaveEnd,
      attachmentPath: attachmentPath,
    );

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message'] ?? t.somethingWentWrong)));

    if (res?['status'] == 1) {
      _reasonController.clear();
      _richTextController.clear();
      _audioPath = null;
      _imageFile = null;
      _documentFile = null;
      _attachmentType = null;
      _leaveType = 'FULL DAY';
      _loadUnapprovedLeaves();
    }
  }

  Future<void> _cancelLeave(int id) async {
    final t = AppLocalizations.of(context)!;

    setState(() => _loading = true);
    final res = await LeaveService().cancelLeave(id);
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res?['message'] ?? t.errorCancellingLeave)));

    if (res?['status'] == 1) _loadUnapprovedLeaves();
  }

  Future<void> _toggleRecording() async {
    final t = AppLocalizations.of(context)!;

    if (_recording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _recording = false;
        _audioPath = path;
        _currentAmplitude = 0.0;
        _attachmentType = 'audio';
        // Clear other attachments
        _imageFile = null;
        _documentFile = null;
      });
    } else {
      if (await _audioRecorder.hasPermission()) {
        // Clear other attachments before starting recording
        setState(() {
          _imageFile = null;
          _documentFile = null;
        });

        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/leave_${DateTime.now().millisecondsSinceEpoch}.mp3';

        await _audioRecorder.start(const RecordConfig(), path: filePath);

        _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 150))
            .listen((amp) {
          if (mounted) {
            setState(() => _currentAmplitude = amp.current);
          }
        });

        setState(() {
          _recording = true;
          _currentAmplitude = 0.0;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.microphonePermissionDenied)));
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;

    if (_playing) {
      await _audioPlayer.pause();
      setState(() => _playing = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      setState(() => _playing = true);
    }
  }

  Future<void> _removeAudio() async {
    if (_playing) await _audioPlayer.stop();

    setState(() {
      _audioPath = null;
      _playing = false;
      if (_attachmentType == 'audio') _attachmentType = null;
    });
  }

  // ================= IMAGE HELPERS =================

  bool _isImage(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png');
  }

  Future<File?> _openCropScreen(File file) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => CropYourImageScreen(imageFile: file),
      ),
    );
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    int quality = 75;
    File output = file;

    for (int i = 0; i < 5; i++) {
      final targetPath =
          '${dir.path}/leave_${DateTime.now().millisecondsSinceEpoch}.jpg';

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

  // ================= CAMERA =================

  Future<void> _openCamera() async {
    if (_loading) return;

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );

      if (photo == null) return;

      File file = File(photo.path);

      // Open crop screen
      final cropped = await _openCropScreen(file);
      if (cropped == null) return;

      // Compress image
      final compressed = await _compressImage(cropped);

      if (!mounted) return;
      setState(() {
        _imageFile = compressed;
        _documentFile = null;
        _audioPath = null;
        _attachmentType = 'image';
        if (_playing) {
          _audioPlayer.stop();
          _playing = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening camera: $e')),
      );
    }
  }

  // ================= FILE PICKER =================

  Future<void> _pickFile() async {
    if (_loading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result == null || result.files.single.path == null) return;

      File file = File(result.files.single.path!);

      // If it's an image, allow cropping
      if (_isImage(file)) {
        final cropped = await _openCropScreen(file);
        if (cropped == null) return;
        file = await _compressImage(cropped);
      }

      if (!mounted) return;
      setState(() {
        if (_isImage(file)) {
          _imageFile = file;
          _documentFile = null;
          _attachmentType = 'image';
        } else {
          _documentFile = file;
          _imageFile = null;
          _attachmentType = 'document';
        }
        _audioPath = null;
        if (_playing) {
          _audioPlayer.stop();
          _playing = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  // ================= REMOVE ATTACHMENTS =================

  void _removeImage() {
    setState(() {
      _imageFile = null;
      if (_attachmentType == 'image') _attachmentType = null;
    });
  }

  void _removeDocument() {
    setState(() {
      _documentFile = null;
      if (_attachmentType == 'document') _attachmentType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.leaveManagement)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUnapprovedLeaves,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildApplyForm(colorScheme, t),
                    const SizedBox(height: 24),
                    Text(t.pendingLeaves,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_pendingLeaves.isEmpty)
                      Center(child: Text(t.noPendingLeaves)),
                    ..._pendingLeaves.map(
                      (l) => Card(
                        child: ListTile(
                          title: Text(
                            "${t.from}: ${l['leave_date_format'] ?? l['leave_date']}"
                            "${l['leave_enddate_format'] != null ? '\n${t.to}: ${l['leave_enddate_format']}' : ''}",
                          ),
                          subtitle: Text(
                            "${l['leave_reason'] ?? ''}\n${t.leaveType}: ${l['leave_type']}",
                          ),
                          trailing: TextButton(
                            onPressed: () => _cancelLeave(l['id']),
                            child: Text(
                              t.cancelLeave,
                              style: const TextStyle(color: Colors.red),
                            ),
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

  Widget _buildApplyForm(ColorScheme colorScheme, AppLocalizations t) {
    return Form(
      key: _formKey,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.applyForLeave,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _leaveType,
                decoration: InputDecoration(labelText: t.leaveType),
                items: [
                  'FULL DAY',
                  'HALF MORNING',
                  'HALF AFTERNOON',
                  'MORE THAN ONE DAY'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _leaveType = v ?? 'FULL DAY'),
              ),
              const SizedBox(height: 12),
              if (_leaveType == 'MORE THAN ONE DAY') ...[
                Row(
                  children: [
                    Text("${t.from}: "),
                    TextButton(
                      onPressed: () => _pickDate(isFrom: true),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_fromDate),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("${t.to}: "),
                    TextButton(
                      onPressed: () => _pickDate(isFrom: false),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_toDate),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Text("${t.date}: "),
                    TextButton(
                      onPressed: () => _pickDate(isFrom: true),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_fromDate),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Rich text editor for reason
              RichTextEditor(
                controller: _richTextController.controller,
                label: t.reason,
                hint: 'Enter your leave reason...',
                height: 200,
                onChanged: (text) {
                  // Update the text controller for validation
                  _reasonController.text = text;
                },
              ),
              // Keep text field for validation (hidden)
              Opacity(
                opacity: 0,
                child: TextFormField(
                  controller: _reasonController,
                  validator: (v) => v == null || v.isEmpty ? t.enterReason : null,
                ),
              ),
              const SizedBox(height: 16),
              // Attachment Section
              Text(
                'Attachment (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // Attachment Options
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _openCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Document'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _toggleRecording,
                      icon: Icon(_recording ? Icons.stop : Icons.mic),
                      label: Text(_recording ? 'Stop' : 'Audio'),
                    ),
                  ),
                ],
              ),
              // Show selected attachments
              if (_imageFile != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          _imageFile!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Image Selected',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              p.basename(_imageFile!.path),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _removeImage,
                      ),
                    ],
                  ),
                ),
              ],
              if (_documentFile != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Selected',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              p.basename(_documentFile!.path),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _removeDocument,
                      ),
                    ],
                  ),
                ),
              ],
              if (_audioPath != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.audiotrack,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audio Recording',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              p.basename(_audioPath!),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _playing ? Icons.pause_circle : Icons.play_circle,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                        onPressed: _togglePlayback,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _removeAudio,
                      ),
                    ],
                  ),
                ),
              ],
              if (_recording) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(t.recordingSpeakNow),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: 20,
                        width: (_currentAmplitude.abs() * 2).clamp(10, 300),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _applyLeave,
                icon: const Icon(Icons.send),
                label: Text(t.submitLeave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
        }
      });
    }
  }
}
