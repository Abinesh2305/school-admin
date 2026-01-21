import 'package:flutter/material.dart';
import '../widgets/image_preview.dart';
import 'youtube_utils.dart';
import '../screens/youtube_player_screen.dart';
import '../screens/video_full_screen.dart';
import '../widgets/audio_player_widget.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DocumentViewer {
  /// Determines file type from URL or extension
  static FileType _getFileType(String url) {
    final lowerUrl = url.toLowerCase();
    final fileName = url.split('/').last.toLowerCase();
    
    // Check for YouTube links
    if (YouTubeUtils.isYouTubeUrl(url)) {
      return FileType.youtube;
    }
    
    // Check by extension
    if (fileName.endsWith('.pdf')) {
      return FileType.pdf;
    } else if (fileName.endsWith('.pptx') || fileName.endsWith('.ppt')) {
      return FileType.pptx;
    } else if (fileName.endsWith('.docx') || fileName.endsWith('.doc')) {
      return FileType.docx;
    } else if (fileName.endsWith('.jpg') || 
               fileName.endsWith('.jpeg') || 
               fileName.endsWith('.png') || 
               fileName.endsWith('.gif') || 
               fileName.endsWith('.webp') ||
               fileName.endsWith('.bmp')) {
      return FileType.image;
    } else if (fileName.endsWith('.mp4') || 
               fileName.endsWith('.mov') || 
               fileName.endsWith('.avi') || 
               fileName.endsWith('.mkv') ||
               fileName.endsWith('.webm')) {
      return FileType.video;
    } else if (fileName.endsWith('.mp3') || 
               fileName.endsWith('.wav') || 
               fileName.endsWith('.m4a') || 
               fileName.endsWith('.aac') ||
               fileName.endsWith('.ogg')) {
      return FileType.audio;
    }
    
    // Check by MIME type in URL or content-type header (if available)
    if (lowerUrl.contains('video') || lowerUrl.contains('mp4')) {
      return FileType.video;
    } else if (lowerUrl.contains('audio') || lowerUrl.contains('mp3')) {
      return FileType.audio;
    } else if (lowerUrl.contains('image') || lowerUrl.contains('jpg') || lowerUrl.contains('png')) {
      return FileType.image;
    }
    
    return FileType.unknown;
  }

  /// Opens a document/file based on its type
  static Future<void> openDocument(BuildContext context, String url, {String? title}) async {
    final fileType = _getFileType(url);
    final fileName = title ?? url.split('/').last;

    switch (fileType) {
      case FileType.pdf:
        await _openPdf(context, url, fileName);
        break;
      case FileType.pptx:
        await _openPptx(context, url, fileName);
        break;
      case FileType.docx:
        await _openDocx(context, url, fileName);
        break;
      case FileType.image:
        ImagePreview.show(context, url);
        break;
      case FileType.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoFullScreen(videoUrl: url),
          ),
        );
        break;
      case FileType.audio:
        _showAudioPlayer(context, url);
        break;
      case FileType.youtube:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YouTubePlayerScreen(videoUrl: url),
          ),
        );
        break;
      case FileType.unknown:
        // Use Google Docs Viewer as fallback for unknown file types
        final viewerUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentWebViewScreen(
              url: viewerUrl,
              title: fileName,
              originalUrl: url,
            ),
          ),
        );
        break;
    }
  }

  /// Opens PDF file using Google Docs Viewer (avoids download and 403 errors)
  static Future<void> _openPdf(BuildContext context, String url, String title) async {
    try {
      // Use Google Docs Viewer to view PDF directly without downloading
      // This avoids 403 errors and works on both Android and iOS
      final viewerUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentWebViewScreen(
            url: viewerUrl,
            title: title,
            originalUrl: url,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open PDF: $e')),
      );
    }
  }

  /// Opens PPTX/PPT file using Microsoft Office Online Viewer (better support for PPT files)
  static Future<void> _openPptx(BuildContext context, String url, String title) async {
    try {
      // Use Microsoft Office Online Viewer for better PPT/PPTX support
      // Falls back to Google Docs Viewer if Office Online doesn't work
      final viewerUrl = 'https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(url)}';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentWebViewScreen(
            url: viewerUrl,
            title: title,
            originalUrl: url,
            fallbackUrl: 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open presentation: $e')),
      );
    }
  }

  /// Opens DOCX/DOC file using Microsoft Office Online Viewer (better support for DOC files)
  static Future<void> _openDocx(BuildContext context, String url, String title) async {
    try {
      // Use Microsoft Office Online Viewer for better DOC/DOCX support
      // Falls back to Google Docs Viewer if Office Online doesn't work
      final viewerUrl = 'https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(url)}';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentWebViewScreen(
            url: viewerUrl,
            title: title,
            originalUrl: url,
            fallbackUrl: 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open document: $e')),
      );
    }
  }

  /// Shows audio player in a dialog
  static void _showAudioPlayer(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Audio Player',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AudioPlayerWidget(audioUrl: url),
            ],
          ),
        ),
      ),
    );
  }

  // Removed _openWithExternalApp method - not used, and download causes 403 errors

  /// Gets file icon based on file type
  static IconData getFileIcon(String url) {
    final fileType = _getFileType(url);
    switch (fileType) {
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.pptx:
        return Icons.slideshow;
      case FileType.docx:
        return Icons.description;
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_library;
      case FileType.audio:
        return Icons.audiotrack;
      case FileType.youtube:
        return Icons.play_circle_filled;
      case FileType.unknown:
        return Icons.insert_drive_file;
    }
  }

  /// Gets file type label
  static String getFileTypeLabel(String url) {
    final fileType = _getFileType(url);
    switch (fileType) {
      case FileType.pdf:
        return 'PDF';
      case FileType.pptx:
        return 'PPTX';
      case FileType.docx:
        return 'DOCX';
      case FileType.image:
        return 'Image';
      case FileType.video:
        return 'Video';
      case FileType.audio:
        return 'Audio';
      case FileType.youtube:
        return 'YouTube';
      case FileType.unknown:
        return 'File';
    }
  }
}

enum FileType {
  pdf,
  pptx,
  docx,
  image,
  video,
  audio,
  youtube,
  unknown,
}

/// WebView screen for displaying documents via Office Online or Google Docs Viewer
class DocumentWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final String originalUrl;
  final String? fallbackUrl;

  const DocumentWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    required this.originalUrl,
    this.fallbackUrl,
  });

  @override
  State<DocumentWebViewScreen> createState() => _DocumentWebViewScreenState();
}

class _DocumentWebViewScreenState extends State<DocumentWebViewScreen> {
  bool _loading = true;
  bool _showError = false;
  bool _triedFallback = false;
  InAppWebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        // Removed download button - files are view-only to avoid 403 errors
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              ),
              ios: IOSInAppWebViewOptions(
                allowsInlineMediaPlayback: true,
              ),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => _loading = true);
            },
            onLoadStop: (controller, url) {
              setState(() => _loading = false);
            },
            onReceivedError: (controller, request, error) {
              // Try fallback URL if available and not already tried
              if (widget.fallbackUrl != null && !_triedFallback) {
                _triedFallback = true;
                _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.fallbackUrl!)));
              } else {
                setState(() {
                  _loading = false;
                  _showError = true;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error loading document: ${error.description}')),
                  );
                }
              }
            },
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_showError && !_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to preview document',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The document may require download or cannot be displayed in the viewer.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

