import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/document_service.dart';
import 'download_document_screen.dart';
import 'crop_your_image.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? _file;
  String? _documentType;
  String? _otherDocumentName;

  bool _uploading = false;
  double _progress = 0;

  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _docTypes = const [
    {'label': 'Aadhaar Certificate', 'value': 'aadhar_certificate'},
    {'label': 'Community Certificate', 'value': 'community_certificate'},
    {'label': 'Birth Certificate', 'value': 'birth_certificate'},
    {'label': 'Income Certificate', 'value': 'income_certificate'},
    {'label': 'Other', 'value': 'other'},
  ];

  /* ================= HELPERS ================= */

bool _isImage(File file) {
  final path = file.path.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png');
}

  /* ================= CROP ================= */

  Future<File?> _openCropScreen(File file) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => CropYourImageScreen(imageFile: file),
      ),
    );
  }

  /* ================= COMPRESS ================= */

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    int quality = 75;
    File output = file;

    for (int i = 0; i < 5; i++) {
      final targetPath =
          '${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.jpg';

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

  /* ================= FILE PICK ================= */

  Future<void> _pickFile() async {
    if (_uploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    File file = File(result.files.single.path!);

    if (_isImage(file)) {
      final cropped = await _openCropScreen(file);
      if (cropped == null) return;
      file = await _compressImage(cropped);
    }

    if (!mounted) return;
    setState(() => _file = file);
  }

  /* ================= CAMERA ================= */

  Future<void> _openCamera() async {
    if (_uploading) return;

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (photo == null) return;

    File file = File(photo.path);

    final cropped = await _openCropScreen(file);
    if (cropped == null) return;

    final compressed = await _compressImage(cropped);

    if (!mounted) return;
    setState(() => _file = compressed);
  }

  /* ================= UPLOAD ================= */

  Future<void> _upload() async {
    if (_uploading) return;

    if (_file == null || _documentType == null) {
      _snack('Please select document type and file');
      return;
    }

    final box = Hive.box('settings');
    final user = box.get('user');

    if (user == null) {
      _snack('User data missing. Please login again.');
      return;
    }


    final int? studentId = user['userdetails']?['id'];
    final int? classId = user['userdetails']?['class_id'];
    final int? sectionId = user['userdetails']?['section_id'];

    if (studentId == null || classId == null || sectionId == null) {
      _snack('Student / Class / Section missing');
      return;
    }

    if (_file!.lengthSync() / 1024 > 500) {
      _snack('File size must be below 500 KB');
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    final result = await DocumentService.uploadDocument(
      studentId: studentId,
      classId: classId,
      sectionId: sectionId,
      documentType: _documentType!,
      otherDocumentName: _otherDocumentName,
      file: _file!,
      onProgress: (v) {
        if (!mounted) return;
        setState(() => _progress = v.clamp(0, 1));
      },
    );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (result['success'] == true) {
      _snack(result['message'] ?? 'Upload successful');

      setState(() {
        _file = null;
        _documentType = null;
        _otherDocumentName = null;
      });
    } else {
      _snack(result['message'] ?? 'Upload failed');
    }
  }

  /* ================= UI HELPERS ================= */

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              items: _docTypes
                  .map(
                    (e) => DropdownMenuItem(
                      value: e['value'],
                      child: Text(e['label']!),
                    ),
                  )
                  .toList(),
              onChanged:
                  _uploading ? null : (v) => setState(() => _documentType = v),
              decoration: const InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(),
              ),
            ),

            if (_documentType == 'other') ...[
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => _otherDocumentName = v,
                decoration: const InputDecoration(
                  labelText: 'Other document name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _openCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('File'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('View Documents'),
                onPressed: _uploading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DownloadDocumentScreen(),
                          ),
                        );
                      },
              ),
            ),

            if (_file != null) ...[
              const SizedBox(height: 12),
              Text('Selected: ${p.basename(_file!.path)}'),
              const SizedBox(height: 8),
              _isImage(_file!)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _file!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 80),
            ],

            const SizedBox(height: 20),

            if (_uploading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _uploading ? null : _upload,
                child: const Text('UPLOAD'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
