import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/document_service.dart';
import 'pdf_viewer_screen.dart';

class DownloadDocumentScreen extends StatefulWidget {
  const DownloadDocumentScreen({super.key});

  @override
  State<DownloadDocumentScreen> createState() => _DownloadDocumentScreenState();
}

class _DownloadDocumentScreenState extends State<DownloadDocumentScreen> {
  bool loading = true;

  Map<String, dynamic>? documentsStatus;
  List<Map<String, dynamic>> otherDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  /* ================= LOAD DOCUMENT STATUS ================= */

  Future<void> _loadDocuments() async {
    setState(() => loading = true);

    final user = Hive.box('settings').get('user');
    if (user == null || user['id'] == null) {
      setState(() => loading = false);
      return;
    }

    final res = await DocumentService.getMyDocumentStatus(userId: user['id']);

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        documentsStatus =
            Map<String, dynamic>.from(res['data']['documents_status'] ?? {});
        otherDocuments = List<Map<String, dynamic>>.from(
            res['data']['other_documents'] ?? []);
      });
    }

    setState(() => loading = false);
  }

  /* ================= HELPERS ================= */

  Map<String, dynamic>? _doc(String key) => documentsStatus?[key];

bool _uploaded(String key) => _doc(key)?['uploaded'] == true;

bool _isImageDoc(String key) => _doc(key)?['file_type'] == 'image';

String? _fileUrl(String key) {
  final doc = _doc(key);
  if (doc == null) return null;

  return doc['file_type'] == 'pdf'
      ? doc['download_url']
      : doc['view_url'];
}


  /* ================= IMAGE PREVIEW ================= */

  Future<void> _previewImage(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final res = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {'Accept': 'image/*'},
        ),
      );

      final file = File(path);
      await file.writeAsBytes(res.data, flush: true);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(16), // ✅ frame margin
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // IMAGE VIEW
              Padding(
                padding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _snack("Unable to open image");
    }
  }

  /* ================= PDF VIEW ================= */

  Future<File> _downloadPdf(String url) async {
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final res = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = res.data;
    if (bytes == null ||
        bytes.length < 4 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46) {
      throw Exception('Invalid PDF');
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _openPdf(String url, String title) async {
    try {
      final file = await _downloadPdf(url);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(file: file, title: title),
        ),
      );
    } catch (_) {
      _snack('Unable to open PDF');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ================= DOCUMENT ROW ================= */

  Widget _docRow(String title, String key) {
  final uploaded = _uploaded(key);
  final url = _fileUrl(key);
  final isImage = _isImageDoc(key);

  return _rowLayout(
    title: title,
    uploaded: uploaded,
    onView: uploaded && url != null
        ? () {
            if (isImage) {
              _previewImage(url);
            } else {
              _openPdf(url, title);
            }
          }
        : null,
  );
}


  /* ================= OTHER DOCUMENT ROW ================= */

  Widget _otherDocRow(Map<String, dynamic> doc) {
  final title = doc['document_name'] ?? 'Other Document';

  final url = doc['file_type'] == 'pdf'
      ? doc['download_url']
      : doc['view_url'];

  final isImage = doc['file_type'] == 'image';

  return _rowLayout(
    title: title,
    uploaded: url != null,
    onView: url == null
        ? null
        : () {
            if (isImage) {
              _previewImage(url);
            } else {
              _openPdf(url, title);
            }
          },
  );
}

  /* ================= COMMON ROW UI ================= */

  Widget _rowLayout({
    required String title,
    required bool uploaded,
    VoidCallback? onView,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(title)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  uploaded ? Icons.check_circle : Icons.cancel,
                  color: uploaded ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  uploaded ? 'Uploaded' : 'Not Uploaded',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: onView != null
                  ? TextButton(
                      onPressed: onView,
                      child: const Text('View'),
                    )
                  : const Text(
                      'No File',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= BUILD ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _docRow('Aadhaar Certificate', 'aadhar'),
                  _docRow('Birth Certificate', 'birth'),
                  _docRow('Income Certificate', 'income'),
                  _docRow('Community Certificate', 'community'),
                  if (otherDocuments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Other Documents',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...otherDocuments.map(_otherDocRow),
                  ],
                ],
              ),
            ),
    );
  }
}
