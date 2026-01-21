import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';
import 'package:html/parser.dart' as html_parser;
import '../l10n/app_localizations.dart';
import '../widgets/reel_notification_item.dart';
import 'dart:async';

class NotificationScreenReels extends StatefulWidget {
  final int? initialIndex;
  final List<dynamic>? notifications;
  
  const NotificationScreenReels({
    super.key,
    this.initialIndex,
    this.notifications,
  });

  @override
  State<NotificationScreenReels> createState() => _NotificationScreenReelsState();
}

class _NotificationScreenReelsState extends State<NotificationScreenReels> {
  final TextEditingController _searchController = TextEditingController();
  late PageController _pageController;
  
  List<dynamic> _notifications = [];
  List<dynamic> _filteredNotifications = [];
  bool _loading = true;
  late Box settingsBox;

  Map<int, String> _categoryColors = {};
  final Set<int> _markedReadOnce = {};
  
  int _currentPageIndex = 0;
  
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  dynamic _selectedCategory;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    
    // If notifications are provided, use them directly
    if (widget.notifications != null && widget.notifications!.isNotEmpty) {
      _filteredNotifications = widget.notifications!;
      _notifications = widget.notifications!;
      _loading = false;
      _currentPageIndex = widget.initialIndex ?? 0;
      _pageController = PageController(initialPage: _currentPageIndex);
      _loadCategoryColors();
    } else {
      _pageController = PageController();
      _loadCategoryColors();
      _loadNotifications();
      
      settingsBox.watch(key: 'user').listen((_) {
        if (mounted) _loadNotifications();
      });
    }

    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (!_pageController.position.isScrollingNotifier.value) {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentPageIndex) {
        setState(() {
          _currentPageIndex = newIndex;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryColors() async {
    try {
      final response = await NotificationService().getCategories();
      if (!mounted) return;

      if (response.isNotEmpty) {
        setState(() {
          _categoryColors = {
            for (var cat in response)
              cat['id']: (cat['text_color'] ?? "#007BFF")
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
        item['read_status'] = (item['read_status'] ?? '').toString().toUpperCase();
        item['is_acknowledged'] = (item['is_acknowledged']?.toString() ?? '0');
        item['request_acknowledge'] = (item['request_acknowledge']?.toString() ?? '0');
      }

      if (!mounted) return;
      setState(() {
        _notifications = data;
        _filteredNotifications = data;
        _loading = false;
        _currentPageIndex = 0;
      });
      
      // Reset to first page after loading and trigger first reel
      if (_pageController.hasClients && _filteredNotifications.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("502.Your internet is slow or unavailable. Please try again."),
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _filterSearch(String query) {
    final filtered = _notifications.where((n) {
      final title = (n['title'] ?? '').toString().toLowerCase();
      final category = (n['post_category'] ?? '').toString().toLowerCase();
      final message = html_parser.parse(n['message'] ?? '').body?.text.toLowerCase() ?? '';
      final q = query.toLowerCase();
      return title.contains(q) || category.contains(q) || message.contains(q);
    }).toList();

    setState(() {
      _filteredNotifications = filtered;
      _currentPageIndex = 0;
    });
    
    if (_pageController.hasClients && _filteredNotifications.isNotEmpty) {
      _pageController.jumpToPage(0);
    }
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

      if (!mounted) return;
      setState(() {
        _notifications = data;
        _filteredNotifications = data;
        _loading = false;
        _currentPageIndex = 0;
      });
      
      if (_pageController.hasClients && _filteredNotifications.isNotEmpty) {
        _pageController.jumpToPage(0);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("503 Your internet is slow or unavailable. Please try again."),
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAsRead(dynamic postId) async {
    if (postId == null) return;
    
    // Convert to int for consistent handling
    final postIdInt = postId is int ? postId : int.tryParse(postId.toString());
    if (postIdInt == null) return;
    
    // Check if already marked as read using int
    if (_markedReadOnce.contains(postIdInt)) return;
    
    // Add to set as int
    _markedReadOnce.add(postIdInt);

    try {
      await NotificationService().markAsRead(postIdInt);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      final readBox = Hive.box('pending_reads');
      readBox.put(postIdInt.toString(), DateTime.now().toString());
    }

    setState(() {
      final postIdStr = postIdInt.toString();
      for (var n in _notifications) {
        if ((n['id'] ?? n['post_id']).toString() == postIdStr) {
          n['read_status'] = 'READ';
        }
      }
      for (var n in _filteredNotifications) {
        if ((n['id'] ?? n['post_id']).toString() == postIdStr) {
          n['read_status'] = 'READ';
        }
      }
    });
  }

  Future<void> _acknowledgePost(dynamic notification) async {
    try {
      final postId = notification['id'] ?? notification['post_id'];
      final postIdInt = postId is int ? postId : int.tryParse(postId.toString());
      
      if (postIdInt != null) {
        final success = await NotificationService().acknowledgePost(postIdInt);
        if (!mounted) return;
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Acknowledged successfully")),
          );
          
          setState(() {
            notification['is_acknowledged'] = '1';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to acknowledge")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to acknowledge: $e")),
      );
    }
  }

  void _handleTtsStateChange(String reelId, String state) {
    // TTS state tracking for UI updates if needed
    // Each reel manages its own TTS instance
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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

    try {
      categories = await NotificationService().getCategories();
      loading = false;

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
            if (loading) {
              NotificationService().getCategories().then((response) {
                if (!mounted) return;
                setModalState(() {
                  categories = response;
                  loading = false;
                  if (_selectedCategory != null) {
                    final match = categories.cast<Map>().where((cat) {
                      return cat['id'].toString() == _selectedCategory['id'].toString();
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.fromDate,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
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
                      child: _buildDateBox(isDark, colorScheme, fromDate, t.selectDate),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.toDate,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
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
                      child: _buildDateBox(isDark, colorScheme, toDate, t.selectDate),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.category,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
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
                    Text(
                      t.type,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
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
                            DropdownMenuItem(value: "post", child: Text("Post Only")),
                            DropdownMenuItem(value: "sms", child: Text("SMS Only")),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              t.clearFilter,
                              style: TextStyle(color: colorScheme.primary),
                            ),
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
                                horizontal: 16,
                                vertical: 12,
                              ),
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

  Widget _buildDateBox(
    bool isDark,
    ColorScheme colorScheme,
    DateTime? date,
    String placeholder,
  ) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _filteredNotifications.isEmpty
                ? Center(
                    child: Text(
                      t.noNoficationFound,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _filteredNotifications.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final notification = _filteredNotifications[index];
                        final notificationId = (notification['id'] ?? notification['post_id']).toString();
                        final categoryId = notification['category_id'] ?? 0;
                        final textColorHex = _categoryColors[categoryId] ?? "#007BFF";
                        final categoryColor = _hexToColor(textColorHex);
                        final isActive = index == _currentPageIndex;
                        
                        // Mark as read will be handled by backend after connection
                        // Removed auto-mark-as-read functionality

                        return ReelNotificationItem(
                          key: ValueKey(notificationId),
                          notification: notification,
                          categoryColor: categoryColor,
                          onMarkAsRead: () {
                            // Mark as read will be handled by backend
                            // This callback is kept for future use but does nothing for now
                          },
                          onAcknowledge: () => _acknowledgePost(notification),
                          isActive: isActive,
                          onTtsStateChange: (state) => _handleTtsStateChange(notificationId, state),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
