import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:html/parser.dart' as html_parser;
import '../widgets/html_message_view.dart';
import 'dart:async';

class MessageReelsReaderScreen extends StatefulWidget {
  final List<dynamic> notifications;
  final int initialIndex;
  final Map<int, String> categoryColors;
  final Function(dynamic) onMarkAsRead;
  final Function(dynamic) onAcknowledge;

  const MessageReelsReaderScreen({
    super.key,
    required this.notifications,
    required this.initialIndex,
    required this.categoryColors,
    required this.onMarkAsRead,
    required this.onAcknowledge,
  });

  @override
  State<MessageReelsReaderScreen> createState() => _MessageReelsReaderScreenState();
}

class _MessageReelsReaderScreenState extends State<MessageReelsReaderScreen> {
  final PageController _pageController = PageController();
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();
  
  int _currentIndex = 0;
  String _currentReadText = "";
  bool _isSpeaking = false;
  bool _isPaused = false;
  String _activeWord = "";
  Timer? _autoReadTimer;
  final Set<int> _markedReadOnce = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupTts();
    _pageController.addListener(_onPageChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.jumpToPage(widget.initialIndex);
        _scheduleAutoRead();
      }
    });
  }

  @override
  void dispose() {
    _autoReadTimer?.cancel();
    _flutterTts.stop();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupTts() {
    _flutterTts.setProgressHandler((text, start, end, word) {
      if (!mounted) return;
      setState(() {
        _activeWord = word;
      });
      _autoScrollToWord(word);
    });

    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    });
  }

  void _onPageChanged() {
    if (!_pageController.position.isScrollingNotifier.value) {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentIndex) {
        setState(() {
          _currentIndex = newIndex;
        });
        _stopReading();
        _markedReadOnce.remove(_currentIndex);
        _scheduleAutoRead();
      }
    }
  }

  void _scheduleAutoRead() {
    _autoReadTimer?.cancel();
    _autoReadTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _markAsReadIfNeeded();
        _startReading();
      }
    });
  }

  void _markAsReadIfNeeded() {
    if (_currentIndex >= 0 && _currentIndex < widget.notifications.length) {
      final notification = widget.notifications[_currentIndex];
      final id = notification['id'] ?? notification['post_id'];
      if (id != null && !_markedReadOnce.contains(id)) {
        _markedReadOnce.add(id);
        widget.onMarkAsRead(id);
      }
    }
  }

  String _getPlainText(dynamic notification) {
    final rawMsg = notification['message'] ?? '';
    return html_parser.parse(rawMsg).body?.text.trim() ?? '';
  }

  void _startReading() {
    if (_currentIndex >= 0 && _currentIndex < widget.notifications.length) {
      final notification = widget.notifications[_currentIndex];
      final message = _getPlainText(notification);
      if (message.isNotEmpty) {
        _readAloud(message);
      }
    }
  }

  Future<void> _readAloud(String text) async {
    if (text.isEmpty) return;
    
    await _flutterTts.stop();
    _currentReadText = text;
    _isPaused = false;

    await _flutterTts.setPitch(1.0);
    await _flutterTts.setLanguage("en-IN");

    final containsTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(text);
    if (containsTamil) {
      await _flutterTts.setVoice({"name": "ta-in-x-tac-network", "locale": "ta-IN"});
    }

    setState(() {
      _isSpeaking = true;
      _isPaused = false;
    });
    
    await _flutterTts.speak(text);
  }

  void _autoScrollToWord(String word) {
    if (word.isEmpty || !_scrollController.hasClients) return;

    final content = _currentReadText;
    final index = content.toLowerCase().indexOf(word.toLowerCase());
    if (index == -1) return;

    final ratio = index / content.length;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = ratio * maxScroll;

    _scrollController.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pauseReading() async {
    final result = await _flutterTts.pause();
    if (result == 1 && mounted) {
      setState(() {
        _isPaused = true;
        _isSpeaking = false;
      });
    }
  }

  Future<void> _resumeReading() async {
    await _readAloud(_currentReadText);
  }

  Future<void> _stopReading() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isPaused = false;
        _isSpeaking = false;
      });
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
    final words = fullText.split(" ");
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : Colors.black87;

    return TextSpan(
      children: words.map((w) {
        final isActive = w.trim().toLowerCase() == _activeWord.trim().toLowerCase();
        return TextSpan(
          text: "$w ",
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue.shade400 : defaultColor,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.notifications.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final notification = widget.notifications[index];
                final title = notification['title'] ?? 'Untitled';
                final category = notification['post_category'] ?? 'General';
                final categoryId = notification['category_id'] ?? 0;
                final textColorHex = widget.categoryColors[categoryId] ?? "#007BFF";
                final tagColor = _hexToColor(textColorHex);
                final rawMsg = notification['message'] ?? '';
                final message = _getPlainText(notification);
                final bgImage = notification['post_theme']?['is_image'];
                final postCreatedAgo = notification['is_notify_datetime'] ?? '';

                return GestureDetector(
                  onTap: _handleTap,
                  onLongPress: _handleLongPress,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: bgImage != null ? Colors.black : colorScheme.surface,
                      image: bgImage != null
                          ? DecorationImage(
                              image: NetworkImage(bgImage),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.5),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (bgImage != null)
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

                        Positioned.fill(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
                            child: _hasHtmlTags(rawMsg)
                                ? HtmlMessageView(
                                    html: rawMsg,
                                    activeWord: _activeWord,
                                  )
                                : RichText(
                                    textAlign: TextAlign.justify,
                                    text: _buildHighlightedText(message),
                                  ),
                          ),
                        ),

                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Expanded(
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 48),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    postCreatedAgo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tagColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: tagColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: tagColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

