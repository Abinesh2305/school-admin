import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/gallery_service.dart';
import '../core/utils/error_handler.dart';
import '../presentation/core/widgets/error_widget.dart' as error_widget;
import '../presentation/core/widgets/empty_state_widget.dart';
import '../presentation/core/widgets/loading_indicator.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<dynamic> items = [];
  bool loading = true;
  int page = 0;
  bool hasMore = true;
  String? errorMessage;
  String? errorCode;

  @override
  void initState() {
    super.initState();
    loadGallery();
  }

  Future<void> loadGallery({bool refresh = false}) async {
    if (refresh) {
      items.clear();
      page = 0;
      hasMore = true;
      errorMessage = null;
      errorCode = null;
    }

    if (!hasMore && !refresh) return;

    setState(() {
      loading = true;
      if (refresh) {
        errorMessage = null;
        errorCode = null;
      }
    });

    try {
      final res = await GalleryService().getGallery(page: page);
      if (!mounted) return;

      final result = ErrorHandler.handleApiResponse(res);

      if (result.success) {
        final data = ErrorHandler.extractList(result.data);

        if (data.length < 20) hasMore = false;

        setState(() {
          loading = false;
          items.addAll(data);
          page += 20;
          errorMessage = null;
          errorCode = null;
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = result.message;
          errorCode = result.errorCode;
        });
        
        ErrorHandler.logError(
          context: 'GalleryScreen.loadGallery',
          error: result.message,
          additionalInfo: {'errorCode': result.errorCode, 'page': page},
        );
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      final message = ErrorHandler.getErrorMessage(e);
      final code = ErrorHandler.getErrorCode(e);
      
      ErrorHandler.logError(
        context: 'GalleryScreen.loadGallery',
        error: e,
        stackTrace: stackTrace,
        additionalInfo: {'page': page},
      );
      
      setState(() {
        loading = false;
        errorMessage = message;
        errorCode = code;
      });
    }
  }

  Widget buildGalleryCard(dynamic g) {
    final List<dynamic> imgs = g['is_gallery_images'] ?? [];

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g['gallery_title'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal image preview list
            if (imgs.isNotEmpty)
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imgs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final imgUrl = imgs[index]['images'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              images: imgs
                                  .map((e) => e['images'] as String)
                                  .toList(),
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imgUrl,
                          height: 160,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.gallery)),
      body: loading && items.isEmpty && errorMessage == null
          ? LoadingIndicator(message: 'Loading gallery...')
          : errorMessage != null && items.isEmpty
              ? error_widget.CustomErrorWidget(
                  message: errorMessage!,
                  errorCode: errorCode,
                  onRetry: () => loadGallery(refresh: true),
                )
              : items.isEmpty
                  ? EmptyStateWidget(
                      message: t.noGallery,
                      icon: Icons.photo_library_outlined,
                      actionLabel: 'Retry',
                      onAction: () => loadGallery(refresh: true),
                    )
                  : RefreshIndicator(
                  onRefresh: () => loadGallery(refresh: true),
                  child: ListView.builder(
                    itemCount: items.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == items.length) {
                        loadGallery();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final g = items[i];
                      return buildGalleryCard(g);
                    },
                  ),
                ),
    );
  }
}

// Full screen image viewer
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (_, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
