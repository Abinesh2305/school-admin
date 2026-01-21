import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/html_message_view.dart';
import '../helpers/document_viewer.dart';
import '../widgets/image_preview.dart';
import '../core/utils/date_formatter.dart';
import 'dart:async';

class ReelNotificationItem extends StatefulWidget {
  final dynamic notification;
  final Color categoryColor;
  final VoidCallback onMarkAsRead;
  final VoidCallback onAcknowledge;
  final bool isActive;
  final Function(String) onTtsStateChange;

  const ReelNotificationItem({
    super.key,
    required this.notification,
    required this.categoryColor,
    required this.onMarkAsRead,
    required this.onAcknowledge,
    required this.isActive,
    required this.onTtsStateChange,
  });

  @override
  State<ReelNotificationItem> createState() => _ReelNotificationItemState();
}

class _ReelNotificationItemState extends State<ReelNotificationItem> {
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  
  String _currentReadText = "";
  bool _isSpeaking = false;
  bool _isPaused = false;
  String _activeWord = "";
  int _activeWordStart = -1; // Track the start position of the active word
  int _pausedPosition = -1; // Track where we paused to resume from that position
  int _resumeOffset = 0; // Offset for resume - used to adjust highlighting positions
  Timer? _autoReadTimer;
  Timer? _scrollTimer;
  bool _hasAutoReadStarted = false;

  @override
  void initState() {
    super.initState();
    // Setup TTS handlers once at initialization
    _setupTts();
    
    if (widget.isActive) {
      _scheduleAutoRead();
    }
  }

  @override
  void didUpdateWidget(ReelNotificationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      // Stop any ongoing TTS from previous reel and wait for it to complete
      _stopAndStartNewRead();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Stop reading when reel becomes inactive
      _stopReading();
      _hasAutoReadStarted = false;
    }
  }
  
  Future<void> _stopAndStartNewRead() async {
    // Stop any ongoing TTS from previous reel
    await _flutterTts.stop();
    // Wait a bit for stop to fully complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted || !widget.isActive) return;
    
    // Reset flags when becoming active so it can start reading
    _hasAutoReadStarted = false;
    _pausedPosition = -1;
    _activeWordStart = -1;
    _activeWord = "";
    _resumeOffset = 0;
    
    // Schedule auto-read after ensuring stop is complete
    _scheduleAutoRead();
  }

  void _setupTts() {
    try {
      _flutterTts.setProgressHandler((String text, int start, int end, String word) {
        if (!mounted) return;
        
        // Adjust start position by resume offset (for highlighting in full text)
        final adjustedStart = start + _resumeOffset;
        
        // Use Future.microtask to defer setState and avoid blocking TTS engine
        Future.microtask(() {
          if (!mounted) return;
          try {
            setState(() {
              _activeWord = word;
              _activeWordStart = adjustedStart; // Track the exact position in full text
              // Update paused position only if we're speaking (not paused)
              if (!_isPaused) {
                _pausedPosition = adjustedStart; // Track current position for resume (in full text)
              }
            });
            
            // Scroll (deferred to avoid blocking)
            if (mounted) {
              Future.microtask(() {
                if (mounted) _autoScrollToWord(adjustedStart, end + _resumeOffset);
              });
            }
          } catch (e) {
            debugPrint('Error in TTS progress handler setState: $e');
          }
        });
      });

      _flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _activeWord = "";
          _activeWordStart = -1;
          _pausedPosition = -1;
          _resumeOffset = 0;
        });
        widget.onTtsStateChange('stopped');
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
          widget.onTtsStateChange('stopped');
        }
      });
    } catch (e) {
      debugPrint('Error setting up TTS: $e');
    }
  }

  void _scheduleAutoRead() {
    // Cancel any existing timer
    _autoReadTimer?.cancel();
    
    // Reset the flag to allow reading to start
    _hasAutoReadStarted = false;
    
    // Delay to ensure previous TTS has fully stopped and widget is ready
    _autoReadTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && widget.isActive && !_hasAutoReadStarted) {
        _hasAutoReadStarted = true;
        _startReading();
      }
    });
  }

  void _startReading() {
    final message = _getPlainText();
    if (message.isEmpty) return;
    
    _currentReadText = message;
    _readAloud(message);
  }

  String _getPlainText() {
    final rawMsg = widget.notification['message'] ?? '';
    // Clean HTML the same way as HtmlMessageView to ensure consistency
    String clean = rawMsg
        .replaceAll(RegExp(r'<figure[^>]*>'), '')
        .replaceAll('</figure>', '')
        // Fix malformed tags with spaces
        .replaceAll(RegExp(r'<\s+'), '<')
        .replaceAll(RegExp(r'>\s+'), '>')
        .replaceAll(RegExp(r'<\s*/\s*'), '</')
        // Fix unclosed tags
        .replaceAll(RegExp(r'<br\s*/?\s*>', caseSensitive: false), '<br/>')
        .replaceAll(RegExp(r'<br\s*</', caseSensitive: false), '<br/>');
    
    // Ensure table structure is valid
    if (clean.contains('<table') && !clean.contains('</table>')) {
      clean = '$clean</table>';
    }
    
    // Extract plain text from cleaned HTML and normalize whitespace to match JavaScript behavior
    final extracted = html_parser.parse(clean).body?.text ?? '';
    // Normalize whitespace: collapse multiple spaces/newlines to single space (matching JavaScript regex)
    return extracted.replaceAll(RegExp(r'[\s\n\r]+'), ' ').trim();
  }

  Future<void> _readAloud(String text, {int offset = 0}) async {
    if (text.isEmpty) return;
    
    try {
      // Set resume offset for highlighting adjustment
      _resumeOffset = offset;
      
      // If offset is 0, this is a new read, otherwise it's a resume
      if (offset == 0) {
        _currentReadText = text;
        _pausedPosition = -1;
      }
      _isPaused = false;

      // Stop any ongoing speech first
      await _flutterTts.stop();
      // Small delay to ensure stop completes before starting new speech
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted) return;

      // Reset active word tracking
      if (mounted) {
        setState(() {
          _activeWord = "";
          if (offset == 0) {
            _activeWordStart = -1;
          }
        });
      }

      // Configure TTS settings
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      
      // Set language and voice
      final containsTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(text);
      if (containsTamil) {
        await _flutterTts.setLanguage("ta-IN");
        await _flutterTts.setVoice({"name": "ta-in-x-tac-network", "locale": "ta-IN"});
      } else {
        await _flutterTts.setLanguage("en-IN");
      }

      // Re-setup handlers AFTER language/voice setup (some platforms reset handlers when language changes)
      // Use a small delay to ensure language/voice is fully set
      await Future.delayed(const Duration(milliseconds: 100));
      _setupTts();
      
      // Don't use awaitSpeakCompletion(true) as it can block and cause issues
      await _flutterTts.awaitSpeakCompletion(false);

      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _isPaused = false;
        });
        widget.onTtsStateChange('speaking');
      }
      
      // Start speaking
      final result = await _flutterTts.speak(text);
      if (result != 1 && mounted) {
        debugPrint('TTS speak failed with result: $result');
        setState(() {
          _isSpeaking = false;
        });
        widget.onTtsStateChange('stopped');
      }
    } catch (e) {
      debugPrint('Error in _readAloud: $e');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        widget.onTtsStateChange('stopped');
      }
    }
  }

  void _autoScrollToWord(int start, int end) {
    if (start < 0 || !_scrollController.hasClients) return;

    final content = _currentReadText;
    if (start >= content.length) return;

    // Cancel any pending scroll to avoid too many animations
    _scrollTimer?.cancel();

    // Debounce scrolling to avoid performance issues and blocking main thread
    _scrollTimer = Timer(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;

      // Calculate scroll position based on the exact character position
      final ratio = start / content.length;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final offset = ratio * maxScroll;

      _scrollController.animateTo(
        offset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pauseReading() async {
    // Store the current position before pausing
    final currentPos = _pausedPosition >= 0 ? _pausedPosition : _activeWordStart;
    
    final result = await _flutterTts.pause();
    if (result == 1 && mounted) {
      setState(() {
        _isPaused = true;
        _isSpeaking = false;
        // Store the position where we paused (use current position or fallback to word start)
        if (currentPos >= 0 && currentPos < _currentReadText.length) {
          _pausedPosition = currentPos;
        }
      });
      widget.onTtsStateChange('paused');
    }
  }

  Future<void> _resumeReading() async {
    // If we have a paused position, resume from there
    if (_pausedPosition >= 0 && _pausedPosition < _currentReadText.length) {
      // Extract the remaining text from the paused position
      final remainingText = _currentReadText.substring(_pausedPosition);
      if (remainingText.trim().isNotEmpty) {
        // Store the offset for highlighting purposes
        final resumePos = _pausedPosition;
        _pausedPosition = -1;
        // Read the remaining text with offset
        await _readAloud(remainingText, offset: resumePos);
        return;
      }
    }
    // Fallback: if no paused position, start from beginning
    _pausedPosition = -1;
    await _readAloud(_currentReadText);
  }

  Future<void> _stopReading() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isPaused = false;
        _isSpeaking = false;
        _activeWord = "";
        _activeWordStart = -1; // Reset position
        _pausedPosition = -1; // Reset paused position
        _resumeOffset = 0; // Reset resume offset
      });
      widget.onTtsStateChange('stopped');
    }
  }

  void _handleTap() {
    if (_isSpeaking) {
      _pauseReading();
    } else if (_isPaused) {
      _resumeReading();
    } else {
      _startReading();
    }
  }

  void _handleLongPress() {
    _stopReading();
  }

  bool _hasHtmlTags(String html) {
    return RegExp(r"<[^>]+>").hasMatch(html);
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  TextSpan _buildHighlightedText(String fullText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : Colors.black87;

    // If no active word position, return normal text
    if (_activeWordStart < 0 || _activeWord.isEmpty) {
    return TextSpan(
        text: fullText,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: defaultColor,
        ),
      );
    }

    // Find all word boundaries by splitting on whitespace while preserving spaces
    List<TextSpan> spans = [];
    final regex = RegExp(r'(\S+|\s+)');
    final matches = regex.allMatches(fullText);
    int currentPos = 0;
    
    for (var match in matches) {
      final segment = match.group(0)!;
      final segmentStart = match.start;
      final segmentEnd = match.end;
      
      // Check if this segment contains the active word at the exact position
      // Only highlight if it's a word (not whitespace) and the position matches
      final isWord = segment.trim().isNotEmpty;
      final isActive = isWord && 
                       _activeWordStart >= segmentStart && 
                       _activeWordStart < segmentEnd &&
                       segment.trim().toLowerCase() == _activeWord.trim().toLowerCase();

      spans.add(TextSpan(
        text: segment,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue.shade400 : defaultColor,
          ),
      ));
  }

    return TextSpan(children: spans);
  }

  @override
  void dispose() {
    _autoReadTimer?.cancel();
    _scrollTimer?.cancel();
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final n = widget.notification;

    final title = n['title'] ?? 'Untitled';
    final category = n['post_category'] ?? 'General';
    final rawMsg = n['message'] ?? '';
    final message = _getPlainText();
    final bgImage = n['post_theme']?['is_image'];
    final notifyDateTime = n['is_notify_datetime'];
    final createdAt = n['created_at'];
    final postCreatedAgo = DateFormatter.formatNotificationDateTime(
      notifyDateTime?.toString(),
      fallbackDateString: createdAt?.toString(),
    );
    final requestAcknowledge = n['request_acknowledge']?.toString() == '1';
    final isAcknowledged = n['is_acknowledged']?.toString() == '1';

    // Attachments
    final rawImages = n['is_image_attachment'] ?? [];
    final images = rawImages is List
        ? rawImages
            .map((item) => (item is Map && item.containsKey('img'))
                ? item['img']
                : item)
            .where((url) => url != null && url.toString().isNotEmpty)
            .toList()
        : [];

    final rawFiles = n['is_files_attachment'] ?? [];
    final files = rawFiles is List
        ? rawFiles
            .map((item) => (item is Map && item.containsKey('img'))
                ? item['img']
                : item)
            .where((url) => url != null && url.toString().isNotEmpty)
            .toList()
        : [];

    final videoUrl = n['is_video_attachment'];
    final audioUrl = n['is_attachment'];
    final youtubeLink = n['youtube_link'];

    final hasAttachments = images.isNotEmpty ||
        files.isNotEmpty ||
        (videoUrl != null && videoUrl.toString().isNotEmpty) ||
        (audioUrl != null && audioUrl.toString().isNotEmpty) ||
        (youtubeLink != null && youtubeLink.toString().isNotEmpty);

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
          color: bgImage != null ? Colors.black : colorScheme.surface,
      ),
      child: bgImage != null
          ? Stack(
        children: [
            Positioned.fill(
              child: Image.network(
                bgImage,
                fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 60,
              ),
            ),
                      );
                    },
                  ),
                ),
            Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.darken,
                    ),
                child: Container(
                      color: Colors.transparent,
                ),
              ),
            ),
          // Gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
                // Main content
          SafeArea(
            child: Column(
              children: [
                // Top: Title and Category
                Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    children: [
                      Text(
                        title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                                color: isDark || bgImage != null
                                    ? Colors.white
                                    : colorScheme.onSurface,
                                shadows: bgImage != null
                                    ? [
                            Shadow(
                                          offset: const Offset(0, 1),
                              blurRadius: 3,
                                          color: Colors.black.withOpacity(0.5),
                            ),
                                      ]
                                    : null,
                        ),
                      ),
                            const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                                color: widget.categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.categoryColor,
                                  width: 1.5,
                                ),
                        ),
                        child: Text(
                          category,
                                style: TextStyle(
                                  color: widget.categoryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                      // Center: Scrollable message content - Full height
                Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: bgImage != null
                                ? Colors.black.withOpacity(0.4)
                                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: bgImage != null
                                ? Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: _hasHtmlTags(rawMsg)
                                ? HtmlMessageView(
                                    html: rawMsg,
                                    activeWord: _activeWord,
                                    activeWordStart: _activeWordStart,
                                  )
                                : RichText(
                                    textAlign: TextAlign.justify,
                                    text: _buildHighlightedText(message),
                                  ),
                          ),
                        ),
                ),

                      // Bottom: Horizontal action bar with time
                Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Bottom left: Time
                            Text(
                          postCreatedAgo,
                          style: TextStyle(
                                fontSize: 12,
                                color: isDark || bgImage != null
                                    ? Colors.white70
                                    : colorScheme.onSurfaceVariant,
                        ),
                      ),

                            // Right side: Horizontal action bar
                            Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Acknowledge button
                                if (requestAcknowledge) ...[
                            _ActionButton(
                              icon: isAcknowledged
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              isActive: isAcknowledged,
                              onTap: isAcknowledged ? null : widget.onAcknowledge,
                                    color: isAcknowledged
                                        ? Colors.green
                                        : Colors.white,
                            ),
                                  const SizedBox(width: 12),
                                ],

                                // Attachments button
                                if (hasAttachments) ...[
                            _ActionButton(
                              icon: Icons.attach_file,
                              isActive: false,
                                    onTap: () => _showAttachmentsModal(
                                      context,
                                      images,
                                      files,
                                      videoUrl,
                                      audioUrl,
                                      youtubeLink,
                                    ),
                                    color: Colors.white,
                            ),
                                  const SizedBox(width: 12),
                                ],

                                // Audio/TTS button (Speaker)
                          _ActionButton(
                                  icon: _isSpeaking
                                ? Icons.volume_up
                                      : _isPaused
                                          ? Icons.pause
                                          : Icons.volume_off,
                                  isActive: _isSpeaking || _isPaused,
                                  onTap: _handleTap,
                                  color: Colors.white,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
            )
          : SafeArea(
              child: Column(
                children: [
                  // Main content when no bgImage
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.categoryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: widget.categoryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: _hasHtmlTags(rawMsg)
                            ? HtmlMessageView(
                                html: rawMsg,
                                activeWord: _activeWord,
                                activeWordStart: _activeWordStart,
                              )
                            : RichText(
                                textAlign: TextAlign.justify,
                                text: _buildHighlightedText(message),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          postCreatedAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (requestAcknowledge) ...[
                              _ActionButton(
                                icon: isAcknowledged
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                isActive: isAcknowledged,
                                onTap: isAcknowledged ? null : widget.onAcknowledge,
                                color: isAcknowledged
                                    ? Colors.green
                                    : Colors.white,
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (hasAttachments) ...[
                              _ActionButton(
                                icon: Icons.attach_file,
                                isActive: false,
                                onTap: () => _showAttachmentsModal(
                                  context,
                                  images,
                                  files,
                                  videoUrl,
                                  audioUrl,
                                  youtubeLink,
                                ),
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                            ],
                            _ActionButton(
                              icon: _isSpeaking
                                  ? Icons.volume_up
                                  : _isPaused
                                      ? Icons.pause
                                      : Icons.volume_off,
                              isActive: _isSpeaking || _isPaused,
                              onTap: _handleTap,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  void _showAttachmentsModal(
    BuildContext context,
    List<dynamic> images,
    List<dynamic> files,
    dynamic videoUrl,
    dynamic audioUrl,
    dynamic youtubeLink,
  ) {
    if (!mounted) return;
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => _AttachmentsModal(
        parentContext: parentContext,
        images: images,
        files: files,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        youtubeLink: youtubeLink,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
            color: isActive ? color : Colors.white.withOpacity(0.3),
            width: isActive ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
          color: color,
              size: 24,
            ),
          ),
    );
  }
}

class _AttachmentsModal extends StatelessWidget {
  final BuildContext parentContext;
  final List<dynamic> images;
  final List<dynamic> files;
  final dynamic videoUrl;
  final dynamic audioUrl;
  final dynamic youtubeLink;

  const _AttachmentsModal({
    required this.parentContext,
    required this.images,
    required this.files,
    required this.videoUrl,
    required this.audioUrl,
    required this.youtubeLink,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attachments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          if (images.isNotEmpty) ...[
            _buildSectionTitle('Images'),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            try {
                              ImagePreview.show(parentContext, images[i]);
                            } catch (e) {
                              // Context is invalid, skip
                            }
                          });
                        },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          images[i],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white54,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Video, YouTube, Audio, and Files as icon buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Video
              if (videoUrl != null && videoUrl.toString().isNotEmpty)
                _buildAttachmentIconButton(
                  icon: Icons.videocam,
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      try {
                        DocumentViewer.openDocument(parentContext, videoUrl);
                      } catch (e) {
                        // Context is invalid, skip
                      }
                    });
                  },
                ),
              
              // YouTube
              if (youtubeLink != null && youtubeLink.toString().isNotEmpty)
                _buildAttachmentIconButton(
                  icon: Icons.play_circle,
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      try {
                        DocumentViewer.openDocument(parentContext, youtubeLink);
                      } catch (e) {
                        // Context is invalid, skip
                      }
                    });
                  },
                ),
              
              // Audio
              if (audioUrl != null && audioUrl.toString().isNotEmpty)
                _buildAttachmentIconButton(
                  icon: Icons.audiotrack,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      try {
                        DocumentViewer.openDocument(parentContext, audioUrl);
                      } catch (e) {
                        // Context is invalid, skip
                      }
                    });
                  },
                ),
              
              // Files (PDF, DOCX, PPTX)
              ...files.map((fileUrl) {
                final fileIcon = DocumentViewer.getFileIcon(fileUrl);
                return _buildAttachmentIconButton(
                  icon: fileIcon,
                  color: _getFileIconColor(fileUrl),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      try {
                        DocumentViewer.openDocument(parentContext, fileUrl);
                      } catch (e) {
                        // Context is invalid, skip
                      }
                    });
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAttachmentIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }

  Color _getFileIconColor(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      return Colors.red;
    } else if (lowerUrl.endsWith('.pptx') || lowerUrl.endsWith('.ppt')) {
      return Colors.orange;
    } else if (lowerUrl.endsWith('.docx') || lowerUrl.endsWith('.doc')) {
      return Colors.blue;
    }
    return Colors.grey;
  }
}
