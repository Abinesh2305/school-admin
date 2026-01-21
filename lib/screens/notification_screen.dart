import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';
import 'youtube_player_screen.dart';
import 'video_full_screen.dart';
import '../widgets/audio_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../l10n/app_localizations.dart';
import '../widgets/html_message_view.dart';
import 'notification_screen_reels.dart';
import '../helpers/document_viewer.dart';
import '../core/utils/date_formatter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _notifications = [];
  List<dynamic> _filteredNotifications = [];
  bool _loading = true;
  late Box settingsBox;

  // Removed FlutterTts - not needed in list view

  Map<int, String> _categoryColors = {};

  final Set<int> _markedReadOnce = {};

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  dynamic _selectedCategory;
  String? _selectedType;

  // Removed TTS-related state - not needed in list view

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    _loadCategoryColors();
    _loadNotifications();

    // Listen for user switch in Hive
    settingsBox.watch(key: 'user').listen((_) {
      if (mounted) _loadNotifications();
    });

    // Removed TTS setup - not needed in list view
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(dynamic postId) async {
    if (postId == null) return;
    if (_markedReadOnce.contains(postId)) return;

    _markedReadOnce.add(postId);

    await NotificationService().markAsRead(postId);

    setState(() {
      for (var n in _notifications) {
        if ((n['id'] ?? n['post_id']).toString() == postId.toString()) {
          n['read_status'] = 'READ';
        }
      }
      for (var n in _filteredNotifications) {
        if ((n['id'] ?? n['post_id']).toString() == postId.toString()) {
          n['read_status'] = 'READ';
        }
      }
    });
  }

  Future<void> _loadCategoryColors() async {
    try {
      final response = await NotificationService().getCategories();
      if (response.isNotEmpty) {
        setState(() {
          _categoryColors = {
            for (var cat in response) cat['id']: cat['text_color']
          };
        });
      }
    } catch (e) {
      debugPrint('Failed to load category colors: $e');
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);

    try {
      final data = await NotificationService().getPostCommunications();

      for (var item in data) {
        item['read_status'] =
            (item['read_status'] ?? '').toString().toUpperCase();
        item['is_acknowledged'] = (item['is_acknowledged']?.toString() ?? '0');
        item['request_acknowledge'] =
            (item['request_acknowledge']?.toString() ?? '0');
      }

      setState(() {
        _notifications = data;
        _filteredNotifications = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading notifications: $e")),
        );
      }
    }
  }

  void _filterSearch(String query) {
    final filtered = _notifications.where((n) {
      final title = (n['title'] ?? '').toString().toLowerCase();
      final category = (n['post_category'] ?? '').toString().toLowerCase();
      final message =
          html_parser.parse(n['message'] ?? '').body?.text.toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
          category.contains(query.toLowerCase()) ||
          message.contains(query.toLowerCase());
    }).toList();
    setState(() => _filteredNotifications = filtered);
  }

  Future<void> _applyFilter() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await NotificationService().getPostCommunications(
        fromDate: _selectedFromDate,
        toDate: _selectedToDate,
        category: _selectedCategory,
        type: _selectedType,
        search: _searchController.text,
      );

      setState(() {
        _notifications = data;
        _filteredNotifications = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching notifications: $e")),
        );
      }
    }
  }

  void _openFilterModal() async {
    DateTime? fromDate = _selectedFromDate;
    DateTime? toDate = _selectedToDate;
    dynamic selectedCategory = _selectedCategory;
    String selectedType = _selectedType ?? "all";

    List<dynamic> categories = [];
    bool loading = true;
    String? errorMsg;

    final t = AppLocalizations.of(context)!;

    // Fetch categories BEFORE bottom sheet opens
    try {
      categories = await NotificationService().getCategories();
      loading = false;

      // Restore selected category
      if (_selectedCategory != null) {
        final match = categories.cast<Map>().where((cat) {
          return cat['id'].toString() == _selectedCategory['id'].toString();
        });

        if (match.isNotEmpty) {
          selectedCategory = match.first;
        }
      }
    } catch (e) {
      loading = false;
      errorMsg = e.toString();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            // Fetch categories once when modal opens
            if (loading) {
              NotificationService().getCategories().then((response) {
                setModalState(() {
                  categories = response;
                  loading = false;

                  if (_selectedCategory != null) {
                    final match = categories.cast<Map>().where((cat) {
                      return cat['id'].toString() ==
                          _selectedCategory['id'].toString();
                    });

                    if (match.isNotEmpty) {
                      selectedCategory = match.first;
                    }
                  }
                });
              }).catchError((e) {
                setModalState(() {
                  errorMsg = e.toString();
                  loading = false;
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.filterNotification,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // From Date
                    Text(t.fromDate,
                        style: TextStyle(color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() => fromDate = picked);
                        }
                      },
                      child: _buildDateBox(
                          isDark, colorScheme, fromDate, t.selectDate),
                    ),
                    const SizedBox(height: 16),

                    // To Date
                    Text(t.toDate,
                        style: TextStyle(color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: toDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() => toDate = picked);
                        }
                      },
                      child: _buildDateBox(
                          isDark, colorScheme, toDate, t.selectDate),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Text(t.category,
                        style: TextStyle(color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          value: selectedCategory,
                          isExpanded: true,
                          hint: Text(
                            loading
                                ? "Loading categories..."
                                : errorMsg != null
                                    ? "Error loading categories"
                                    : "Select category",
                          ),
                          onChanged: loading || errorMsg != null
                              ? null
                              : (value) {
                                  setModalState(() => selectedCategory = value);
                                },
                          items: [
                            DropdownMenuItem<dynamic>(
                              value: null,
                              child: Text(t.allCategory),
                            ),
                            ...categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat['name'] ?? 'Unnamed'),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type Dropdown
                    Text(t.type,
                        style: TextStyle(color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          onChanged: (value) {
                            setModalState(() => selectedType = value ?? "all");
                          },
                          items: const [
                            DropdownMenuItem(value: "all", child: Text("All")),
                            DropdownMenuItem(
                                value: "post", child: Text("Post Only")),
                            DropdownMenuItem(
                                value: "sms", child: Text("SMS Only")),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFromDate = null;
                                _selectedToDate = null;
                                _selectedCategory = null;
                                _selectedType = "all";
                                _searchController.clear();
                              });

                              Navigator.pop(context);
                              _loadNotifications();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colorScheme.primary),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(t.clearFilter,
                                style: TextStyle(color: colorScheme.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedFromDate = fromDate;
                                _selectedToDate = toDate;
                                _selectedCategory = selectedCategory;
                                _selectedType = selectedType;
                              });

                              _applyFilter();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(t.applyFilter),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t.cancel),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for date box
  Widget _buildDateBox(bool isDark, ColorScheme colorScheme, DateTime? date,
      String placeholder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date != null
                ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
                : placeholder,
            style: TextStyle(color: colorScheme.onSurface),
          ),
          const Icon(Icons.calendar_today, size: 18),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Cannot open link")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                                .withOpacity(0.3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterSearch,
                        decoration: InputDecoration(
                          hintText: t.searchNotifications,
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _openFilterModal,
                    ),
                  ),
                ],
              ),
            ),

            // Notification List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: _filteredNotifications.isEmpty
                          ? Center(child: Text(t.noNoficationFound))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final n = _filteredNotifications[index];
                                final title = n['title'] ?? 'Untitled';
                                final rawMsg = n['message'] ?? '';
                                final message = html_parser
                                        .parse(rawMsg)
                                        .body
                                        ?.text
                                        .trim() ??
                                    '';
                                final category =
                                    n['post_category'] ?? 'General';
                                final categoryId = n['category_id'] ?? 0;
                                final textColorHex =
                                    // _categoryColors[categoryId] ?? "#007BFF";
                                    "#007BFF";

                                final bgImage = n['post_theme']?['is_image'];
                                final tagColor = _hexToColor(textColorHex);
                                final notifyDateTime = n['is_notify_datetime'];
                                final createdAt = n['created_at'];
                                final postCreatedAgo = DateFormatter.formatNotificationDateTime(
                                  notifyDateTime?.toString(),
                                  fallbackDateString: createdAt?.toString(),
                                );

                                // Attachments
                                final rawImages =
                                    n['is_image_attachment'] ?? [];
                                final images = rawImages is List
                                    ? rawImages
                                        .map((item) => (item is Map &&
                                                item.containsKey('img'))
                                            ? item['img']
                                            : item)
                                        .where((url) =>
                                            url != null &&
                                            url.toString().isNotEmpty)
                                        .toList()
                                    : [];

                                final rawFiles = n['is_files_attachment'] ?? [];
                                final videoUrl = n['is_video_attachment'];
                                final audioUrl = n[
                                    'is_attachment']; // or use n['media_attachment'] if that's where mp3 is

                                final files = rawFiles is List
                                    ? rawFiles
                                        .map((item) => (item is Map &&
                                                item.containsKey('img'))
                                            ? item['img']
                                            : item)
                                        .where((url) =>
                                            url != null &&
                                            url.toString().isNotEmpty)
                                        .toList()
                                    : [];

                                return VisibilityDetector(
                                  key: Key("post_${n['id'] ?? n['post_id']}"),
                                  onVisibilityChanged: (info) {
                                    if (info.visibleFraction > 0.45) {
                                      final id = n['id'] ?? n['post_id'];
                                      if ((n['read_status'] ?? '') != 'READ') {
                                        _markAsRead(id);
                                        n['read_status'] = 'READ';
                                      }
                                    }
                                  },
                                  child: Card(
                                    color: (n['read_status'] == 'READ')
                                        ? colorScheme.surfaceContainerHighest
                                            .withOpacity(0.3)
                                        : colorScheme.primary.withOpacity(0.10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title + Category
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        (n['read_status'] ==
                                                                'READ')
                                                            ? FontWeight.normal
                                                            : FontWeight.bold,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: tagColor
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: TextStyle(
                                                    color: tagColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // YouTube preview (now directly below title)
                                          if (n['youtube_link'] != null &&
                                              n['youtube_link']
                                                  .toString()
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          YouTubePlayerScreen(
                                                        videoUrl:
                                                            n['youtube_link'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  height: 200,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    ),
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: Image.network(
                                                            'https://img.youtube.com/vi/${_extractYouTubeId(n['youtube_link'])}/hqdefault.jpg',
                                                      fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Container(
                                                                color: Colors.grey[900],
                                                  child: const Center(
                                                                  child: Icon(
                                                                    Icons.image_not_supported,
                                                                    color: Colors.white54,
                                                                    size: 40,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      const Center(
                                                    child: Icon(
                                                      Icons.play_circle_fill,
                                                      color: Colors.white,
                                                      size: 60,
                                                    ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                          const SizedBox(height: 12),

                                          // Message area
                                          Container(
                                            width: double.infinity,
                                            constraints: const BoxConstraints(
                                              maxHeight: 150, // Reduced height for list view preview
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: bgImage != null
                                                ? Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(10),
                                                          child: Image.network(
                                                            bgImage,
                                                      fit: BoxFit.cover,
                                                            alignment: Alignment.topCenter,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Container(
                                                                color: colorScheme
                                                                    .surfaceContainerHighest
                                                                    .withOpacity(0.3),
                                                                child: const Center(
                                                                  child: Icon(
                                                                    Icons.image_not_supported,
                                                                    color: Colors.grey,
                                                                    size: 40,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                            ),
                                                      Positioned.fill(
                                            child: Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                16,
                                                bgImage != null ? 100 : 16,
                                                16,
                                                              16), // top padding for bg text
                                                          child: GestureDetector(
                                                            onTap: () {
                                                              // Navigate to reels view
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => NotificationScreenReels(
                                                                    initialIndex: index,
                                                                    notifications: _filteredNotifications,
                                                          ),
                                                      ),
                                                              );
                                                            },
                                                            child: Container(
                                                              width: double.infinity,
                                                              constraints: const BoxConstraints(
                                                                maxHeight: 120,
                                                              ),
                                                              child: SingleChildScrollView(
                                                                physics: const NeverScrollableScrollPhysics(),
                                                                child: _hasHtmlTags(rawMsg)
                                                                    ? HtmlMessageView(
                                                                        html: rawMsg,
                                                                        activeWord: '',
                                                                        ignorePointer: true, // Allow taps to pass through
                                                                      )
                                                                    : RichText(
                                                                        textAlign: TextAlign.justify,
                                                                        text: TextSpan(
                                                                          text: message.length > 200 
                                                                              ? '${message.substring(0, 200)}...' 
                                                                              : message,
                                                                          style: TextStyle(
                                                                            fontSize: 15,
                                                                            height: 1.5,
                                                                            color: isDark ? Colors.white70 : Colors.black87,
                                                                          ),
                                                                        ),
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                                  )
                                                  : Padding(
                                                      padding: const EdgeInsets.all(16),
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          // Navigate to reels view
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => NotificationScreenReels(
                                                                initialIndex: index,
                                                                notifications: _filteredNotifications,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          width: double.infinity,
                                                          constraints: const BoxConstraints(
                                                            maxHeight: 120,
                                                          ),
                                                          child: SingleChildScrollView(
                                                            physics: const NeverScrollableScrollPhysics(),
                                                            child: _hasHtmlTags(rawMsg)
                                                                ? HtmlMessageView(
                                                                    html: rawMsg,
                                                                    activeWord: '',
                                                                    ignorePointer: true, // Allow taps to pass through
                                                                  )
                                                                : RichText(
                                                                    textAlign: TextAlign.justify,
                                                                    text: TextSpan(
                                                                      text: message.length > 200 
                                                                          ? '${message.substring(0, 200)}...' 
                                                                          : message,
                                                                      style: TextStyle(
                                                                        fontSize: 15,
                                                                        height: 1.5,
                                                                        color: isDark ? Colors.white70 : Colors.black87,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                              ),
                                            ),
                                          ),

                                          // Attachments section
                                          if (images.isNotEmpty ||
                                              files.isNotEmpty ||
                                              (videoUrl != null &&
                                                  videoUrl
                                                      .toString()
                                                      .isNotEmpty) ||
                                              (audioUrl != null &&
                                                  audioUrl
                                                      .toString()
                                                      .isNotEmpty))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12, bottom: 4),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Audio Attachment
                                                  if (audioUrl != null &&
                                                      audioUrl
                                                          .toString()
                                                          .isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          "Audio:",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        AudioPlayerWidget(
                                                            audioUrl: audioUrl),
                                                      ],
                                                    ),
                                                  const SizedBox(height: 16),

                                                  // Video Attachment
                                                  if (videoUrl != null &&
                                                      videoUrl
                                                          .toString()
                                                          .isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          "Video:",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        GestureDetector(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    VideoFullScreen(
                                                                        videoUrl:
                                                                            videoUrl),
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            height: 200,
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.black87,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                            child: const Center(
                                                              child: Icon(
                                                                Icons
                                                                    .play_circle_fill,
                                                                color: Colors
                                                                    .white,
                                                                  size: 60),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  const SizedBox(height: 12),

                                                  // Existing image attachments
                                                  if (images.isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          "Images:",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        SizedBox(
                                                          height: 100,
                                                          child:
                                                              ListView.builder(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            itemCount:
                                                                images.length,
                                                            itemBuilder:
                                                                (context, i) {
                                                              final img =
                                                                  images[i];
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            8),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () =>
                                                                      _showFullImage(
                                                                    context,
                                                                          img),
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    child: Image
                                                                        .network(
                                                                      img,
                                                                      width:
                                                                          100,
                                                                      height:
                                                                          100,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      errorBuilder: (context, error, stackTrace) {
                                                                        return Container(
                                                                          width: 100,
                                                                          height: 100,
                                                                          color: Colors.grey[300],
                                                                          child: const Icon(
                                                                            Icons.image_not_supported,
                                                                            color: Colors.grey,
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
                                                      ],
                                                    ),
                                                  const SizedBox(height: 10),

                                                  // Existing file attachments - Show as icons
                                                  if (files.isNotEmpty)
                                                    Wrap(
                                                      spacing: 12,
                                                      runSpacing: 12,
                                                      children: files.map<Widget>(
                                                              (fileUrl) {
                                                          final fileIcon = DocumentViewer.getFileIcon(fileUrl);
                                                          Color iconColor;
                                                          final lowerUrl = fileUrl.toLowerCase();
                                                          if (lowerUrl.endsWith('.pdf')) {
                                                            iconColor = Colors.red;
                                                          } else if (lowerUrl.endsWith('.pptx') || lowerUrl.endsWith('.ppt')) {
                                                            iconColor = Colors.orange;
                                                          } else if (lowerUrl.endsWith('.docx') || lowerUrl.endsWith('.doc')) {
                                                            iconColor = Colors.blue;
                                                          } else {
                                                            iconColor = Colors.grey;
                                                          }
                                                          
                                                          return GestureDetector(
                                                            onTap: () {
                                                              DocumentViewer.openDocument(context, fileUrl);
                                                            },
                                                            child: Container(
                                                              width: 60,
                                                              height: 60,
                                                              decoration: BoxDecoration(
                                                                color: iconColor.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(
                                                                  color: iconColor.withOpacity(0.3),
                                                                  width: 1.5,
                                                                  ),
                                                                ),
                                                              child: Icon(
                                                                fileIcon,
                                                                color: iconColor,
                                                                size: 28,
                                                            ),
                                                          ),
                                                        );
                                                        },
                                                      ).toList(),
                                                    ),
                                                ],
                                              ),
                                            ),

                                          // Footer: is_notify_datetime
                                          const SizedBox(
                                              height: 12), // Added space above
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              postCreatedAgo,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Acknowledge section
                                          if (n['request_acknowledge'] == '1' &&
                                              n['is_acknowledged'] == '0')
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.check,
                                                    size: 18),
                                                label:
                                                    const Text("Acknowledge"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colorScheme.primary,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    await NotificationService()
                                                        .acknowledgePost(
                                                            n['id']);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            "Acknowledged successfully"),
                                                      ),
                                                    );
                                                    _loadNotifications();
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            "Failed to acknowledge: $e"),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          if (n['request_acknowledge'] == '1' &&
                                              n['is_acknowledged'] == '1')
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  "Acknowledged",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(Icons.broken_image,
                            color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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

  // Removed _buildHighlightedText - not needed in list view

  String _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v']!;
    } else if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return '';
  }
}
