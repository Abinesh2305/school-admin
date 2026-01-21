import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'l10n/app_localizations.dart';
import 'dart:convert';
import 'widgets/force_update_overlay.dart';
import 'dart:async';

// Core
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';

// Infrastructure
import 'infrastructure/storage/storage_service.dart';
import 'infrastructure/storage/preferences_service.dart';

// Presentation
import 'presentation/core/theme/app_theme.dart';

// Features (keeping existing imports for now - to be refactored)
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/homework_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/leave_screen.dart';
import 'widgets/top_nav_bar.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/user_service.dart';
import 'services/home_service.dart';
import 'services/fcm_helper.dart';
import 'helpers/greeting_helper.dart';

// Global navigator key for navigation even when app is not in foreground
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background FCM handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await Hive.openBox(AppConstants.storageBoxSettings);
}

/// Main entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize App Configuration
  await AppConfig.initialize();
  
  // Initialize Hive storage
  await Hive.initFlutter();
  await StorageService.initialize();

  // Initialize SQLite for preferences
  await PreferencesService.initialize();

  // Initialize Firebase Messaging
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize Local Notifications
  const androidSettings =
      AndroidInitializationSettings('@drawable/notification_icon');
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        final fakeMessage =
            RemoteMessage(data: Map<String, dynamic>.from(data));
        await _handleUserAndNavigate(fakeMessage);
      }
    },
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Get saved preferences from SQLite
  String savedTheme = await PreferencesService.getThemeMode();
  String savedLanguage = await PreferencesService.getLanguage();

  runApp(SplashWrapper(
    savedTheme: savedTheme,
    savedLanguage: savedLanguage,
  ));
}

/// Shared logic to switch user and open notification tab
Future<void> _handleUserAndNavigate(RemoteMessage? message) async {
  final box = StorageService.settingsBox;

  final targetUserId = message?.data['target_user_id'];

  if (targetUserId != null) {
    final linkedUsers = box.get(AppConstants.keyLinkedUsers, defaultValue: []);
    final mainUser = box.get(AppConstants.keyUser);

    List allUsers = [];
    if (mainUser != null) allUsers.add(mainUser);
    allUsers.addAll(linkedUsers);

    var targetUser = allUsers.firstWhere(
      (u) => u['id'].toString() == targetUserId.toString(),
      orElse: () => null,
    );

    if (targetUser != null) {
      await box.put(AppConstants.keyToken, targetUser['api_token']);
      await box.put(AppConstants.keyUser, targetUser);

      await navigatorKey.currentState?.context
          .findAncestorStateOfType<_MainNavigationScreenState>()
          ?.resetFcmSubscriptions();
    }
  }

  bool openHomework = false;
  bool openNotification = false;

  final msgType = message?.data['type']?.toString();
  final navigate = message?.data['navigate']?.toString();

  if (msgType == "5" || navigate == "homework") {
    openHomework = true;
  } else {
    openNotification = true;
  }

  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => MainNavigationScreen(
        onToggleTheme: () {},
        onToggleLanguage: () {},
        openHomeworkTab: openHomework,
        openNotificationTab: openNotification,
      ),
    ),
    (route) => false,
  );
}

class SplashWrapper extends StatelessWidget {
  final String savedTheme;
  final String savedLanguage;

  const SplashWrapper({
    super.key,
    required this.savedTheme,
    required this.savedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return MyApp(
      savedTheme: savedTheme,
      savedLanguage: savedLanguage,
    );
  }
}

class MyApp extends StatefulWidget {
  final String savedTheme;
  final String savedLanguage;

  const MyApp({
    super.key,
    required this.savedTheme,
    required this.savedLanguage,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _themeMode = _getThemeFromSaved(widget.savedTheme);
    _locale = Locale(widget.savedLanguage);
  }

  ThemeMode _getThemeFromSaved(String theme) {
    if (theme == 'light') return ThemeMode.light;
    if (theme == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    try {
      await PreferencesService.saveThemeMode(mode.name);
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error saving theme mode: $e');
    }
  }

  void _toggleTheme() {
    // Cycle through: light -> dark -> system -> light
    if (_themeMode == ThemeMode.light) {
      _setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      _setThemeMode(ThemeMode.system);
    } else {
      _setThemeMode(ThemeMode.light);
    }
  }

  void _toggleLanguage() async {
    try {
      String current = await PreferencesService.getLanguage();
    String newLang = current == 'en' ? 'ta' : 'en';

    setState(() => _locale = Locale(newLang));
      await PreferencesService.saveLanguage(newLang);

      // Also update in Hive for user data (if needed for API calls)
      final box = StorageService.settingsBox;
    final user = box.get(AppConstants.keyUser);
    if (user != null) {
      user['language'] = newLang;
      box.put(AppConstants.keyUser, user);
    }

    // TODO: Update language via API
    // await DioClient.dio.post(
    //   ApiEndpoints.updateLanguage,
    //   data: {'user_id': user?['id'], 'language': newLang},
    // );

      // Navigate to refresh the app with new language
      navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LaunchDecider(
            onToggleTheme: _toggleTheme, onToggleLanguage: _toggleLanguage),
      ),
        (route) => false, // Remove all previous routes
    );
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error toggling language: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ta')],
      home: LaunchDecider(
        onToggleTheme: _toggleTheme,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}

class LaunchDecider extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const LaunchDecider({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<LaunchDecider> createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<LaunchDecider> {
  bool _checkingUpdate = true;
  bool _forceUpdateRequired = false;
  final String _updateMessage = '';
  final String _latestVersion = '';

  @override
  void initState() {
    super.initState();
    _checkForForceUpdate();
  }

  Future<void> _checkForForceUpdate() async {
    // For admin app, skip force update check to avoid blocking
    // Admin apps typically don't need force updates as they're managed differently
    debugPrint('Skipping force update check for admin app');
    setState(() {
      _checkingUpdate = false;
      _forceUpdateRequired = false;
    });
    return;
    
    // Uncomment below if you want to enable force update check for admin app
    /*
    try {
      // Check for force update from backend with timeout
      // For admin app, we don't want to block on update check
      final updateResult = await ForceUpdateService.checkForUpdate()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('Update check timed out, allowing app to continue');
              return ForceUpdateResult(updateRequired: false);
            },
          );

      if (updateResult.updateRequired) {
        setState(() {
          _forceUpdateRequired = true;
          _updateMessage = updateResult.message ?? 'A new version is available. Please update to continue.';
          _latestVersion = updateResult.latestVersion ?? '';
          _checkingUpdate = false;
        });
        return;
      }

      // No force update required, proceed normally
      setState(() {
        _checkingUpdate = false;
      });
    } catch (e) {
      debugPrint('Error checking for force update: $e');
      // On error, allow app to continue (don't block)
      // This is critical for admin app
      setState(() {
        _checkingUpdate = false;
      });
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking for updates
    if (_checkingUpdate) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show force update overlay if update is required
    if (_forceUpdateRequired) {
      return ForceUpdateOverlay(
        message: _updateMessage,
        latestVersion: _latestVersion,
      );
    }

    // Normal app flow
    final box = StorageService.settingsBox;

    return box.get(AppConstants.keyUser) != null
        ? MainNavigationScreen(
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
          )
        : LoginScreen(
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
          );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool openNotificationTab;
  final bool openLeaveTab;
  final bool openFeesTab;
  final bool openHomeworkTab;
  final bool openAttendanceTab;

  const MainNavigationScreen({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.openNotificationTab = false,
    this.openLeaveTab = false,
    this.openFeesTab = false,
    this.openHomeworkTab = false,
    this.openAttendanceTab = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  DateTime? _lastPressedTime;
  String? _lastLanguage;
  String _currentLanguage = AppConstants.defaultLanguage;

  @override
  void initState() {
    super.initState();

    // Get current language to detect changes
    PreferencesService.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _lastLanguage = lang;
          _currentLanguage = lang;
        });
      }
    });

    resetFcmSubscriptions();
    
    // Show greeting when app opens or when language changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGreetingOnAppOpen();
    });

    if (widget.openNotificationTab) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _notificationClickHandler());
    } else if (widget.openLeaveTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leaveClickHandler());
    } else if (widget.openFeesTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 5);
        _pageController.jumpToPage(5);
      });
    } else if (widget.openHomeworkTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 1);
        _pageController.jumpToPage(1);
      });
    } else if (widget.openAttendanceTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 4);
        _pageController.jumpToPage(4);
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final senderName = message.data['sender_name'] ?? '';
      final title = message.data['title'] ?? 'Notification';
      final body = message.data['body'] ?? '';
      final displayTitle =
          senderName.isNotEmpty ? "$senderName – $title" : title;

      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/notification_icon',
      );

      const platformDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        0,
        displayTitle,
        body,
        platformDetails,
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    _checkInitialMessage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if language changed and show greeting
    // Ensure database is initialized before querying
    PreferencesService.initialize().then((_) {
      return PreferencesService.getLanguage();
    }).then((currentLanguage) {
      if (mounted && _lastLanguage != null && _lastLanguage != currentLanguage) {
        setState(() {
          _lastLanguage = currentLanguage;
          _currentLanguage = currentLanguage;
        });
        // Show greeting with new language
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGreetingOnAppOpen();
        });
      }
    }).catchError((error) {
      // Silently handle database errors - use default language
      debugPrint('Error getting language preference: $error');
    });
  }

  Future<void> _checkInitialMessage() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) await _handleNotificationClick(msg);
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    await _handleUserAndNavigate(message);
  }

  Future<void> resetFcmSubscriptions() async {
    final box = StorageService.settingsBox;
    final mainUser = box.get(AppConstants.keyUser);
    final linkedUsers = box.get(AppConstants.keyLinkedUsers, defaultValue: []);

    if (mainUser == null) return;

    final schoolId = mainUser['school_college_id'];

    final users = <Map<String, dynamic>>[];
    users.add(Map<String, dynamic>.from(mainUser));
    for (var u in linkedUsers) {
      if (u is Map) users.add(Map<String, dynamic>.from(u));
    }

    final uniqueUsers = {for (var u in users) u['id']: u}.values.toList();

    await FirebaseMessaging.instance
        .unsubscribeFromTopic("${AppConstants.topicPrefixSchool}$schoolId");

    for (var u in uniqueUsers) {
      final uid = u['id'];
      final details = (u['userdetails'] ?? {}) as Map;

      final sectionId = details['section_id'] ??
          details['is_section_id'] ??
          details['is_section_name'] ??
          0;

      await FirebaseMessaging.instance.unsubscribeFromTopic("${AppConstants.topicPrefixScholar}$uid");
      await FirebaseMessaging.instance
          .unsubscribeFromTopic("${AppConstants.topicPrefixSection}$sectionId");

      final groups = u['groups'] ?? [];
      for (var g in groups) {
        final gid = g['id'];
        if (gid != null) {
          await FirebaseMessaging.instance.unsubscribeFromTopic("${AppConstants.topicPrefixGroup}$gid");
        }
      }
    }

    await safeSubscribe("${AppConstants.topicPrefixSchool}$schoolId");

    for (var u in uniqueUsers) {
      final uid = u['id'];
      final details = (u['userdetails'] ?? {}) as Map;

      final sectionId = details['section_id'] ??
          details['is_section_id'] ??
          details['is_section_name'] ??
          0;

      await safeSubscribe("${AppConstants.topicPrefixScholar}$uid");
      await safeSubscribe("${AppConstants.topicPrefixSection}$sectionId");

      final groups = u['groups'] ?? [];
      for (var g in groups) {
        final gid = g['id'];
        if (gid != null) await safeSubscribe("${AppConstants.topicPrefixGroup}$gid");
      }
    }
  }

  void _notificationClickHandler() {
    setState(() => _currentIndex = 2);
    _pageController.jumpToPage(2);
  }

  void _feesClickHandler() {
    setState(() => _currentIndex = 5);
    _pageController.jumpToPage(5);
  }

  void _homeworkClickHandler() {
    setState(() => _currentIndex = 1);
    _pageController.jumpToPage(1);
  }

  void _onNavigate(int index) {
    if (_currentIndex == index) return;
    
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
    );
  }

  void _leaveClickHandler() {
    setState(() => _currentIndex = 6);
    _pageController.jumpToPage(6);
  }

  Future<bool?> _showExitDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        colorScheme.surface,
                        colorScheme.surfaceContainerHighest,
                      ]
                    : [
                        Colors.white,
                        colorScheme.primary.withOpacity(0.05),
                      ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Exit image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/exit_image.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image fails to load
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary.withOpacity(0.2),
                              colorScheme.primary.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title with student theme
                Text(
                  'Exit App?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Are you sure you want to exit?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Buttons with student-themed styling
                Row(
                  children: [
                    // Cancel button (Stay button)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text(
                          'Stay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Exit button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.exit_to_app, size: 20, color: Colors.white),
                        label: const Text(
                          'Exit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGreetingOnAppOpen() {
    // Only show greeting once when app first opens, not on tab switches
    final box = StorageService.settingsBox;
    final user = box.get(AppConstants.keyUser);
    
    if (user == null) return;
    
    final userName = user['name']?.toString() ?? '';
    
    // Delay slightly to ensure context is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final localizations = AppLocalizations.of(context);
      if (localizations == null) return;
      
      try {
        final greeting = GreetingHelper.getGreetingWithName(localizations, userName);
        final emoji = GreetingHelper.getGreetingEmoji();
        
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
      } catch (e) {
        debugPrint('Error showing greeting: $e');
      }
    });
  }

  void _logoutUser() async {
    final box = StorageService.settingsBox;
    final firstLaunch = box.get(AppConstants.keyIsFirstLaunch, defaultValue: false);

    final user = box.get(AppConstants.keyUser);
    final fcm = await FirebaseMessaging.instance.getToken();
    if (user != null) {
      // TODO: Call logout API
      // try {
      //   await DioClient.dio.post(ApiEndpoints.logout, data: {
      //     'user_id': user['id'],
      //     'fcm_token': fcm ?? '',
      //     'device_id': 'device_001',
      //     'device_type': AppConstants.deviceTypeAndroid,
      //   });
      // } catch (_) {}
    }

    await box.clear();
    await box.put(AppConstants.keyIsFirstLaunch, firstLaunch);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
      (route) => false,
    );
  }

  void _showUserSwitcher() async {
    final box = StorageService.settingsBox;
    List scholars = box.get(AppConstants.keyLinkedUsers, defaultValue: []);
    final currentUser = box.get(AppConstants.keyUser);
    String? selectedUserId = currentUser?['id']?.toString();

    if (scholars.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      scholars = await UserService().getMobileScholars();
      Navigator.pop(context);

      if (scholars.isNotEmpty) {
        await box.put(AppConstants.keyLinkedUsers, scholars);
      }
    }

    if (scholars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No linked accounts found')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Text(
                        'Switch Student',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: scholars.length,
                        itemBuilder: (context, index) {
                          final s = scholars[index];
                          final id = s['id']?.toString();
                          final profileImage = s['is_profile_image'] ??
                              "https://www.clasteqsms.com/multischool/public/image/default.png";

                          return RadioListTile<String>(
                            value: id ?? '',
                            groupValue: selectedUserId,
                            onChanged: (value) async {
                              if (value == null) return;

                              setDialogState(() => selectedUserId = value);

                              await box.put(AppConstants.keyToken, s['api_token']);
                              await box.put(AppConstants.keyUser, s);

                              List linkedUsers =
                                  box.get(AppConstants.keyLinkedUsers, defaultValue: []);
                              if (!linkedUsers.any((u) => u['id'] == s['id'])) {
                                linkedUsers.add(s);
                                await box.put(AppConstants.keyLinkedUsers, linkedUsers);
                              }

                              Navigator.pop(dialogContext);
                              setState(() {});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Switched to ${s['name']}")),
                              );

                              resetFcmSubscriptions();
                              HomeService.syncHomeContents();
                            },
                            title: Text(s['name'] ?? "Unknown"),
                            subtitle: Text(
                                "Class: ${s['userdetails']['is_class_name'] ?? ''} • Section: ${s['userdetails']['is_section_name'] ?? ''}"),
                            secondary: CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(profileImage),
                              backgroundColor: Colors.grey.shade300,
                            ),
                            activeColor: Theme.of(context).colorScheme.primary,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          "Close",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final box = StorageService.settingsBox;
    final rawUser = box.get(AppConstants.keyUser);
    final Map<String, dynamic>? user =
        rawUser != null ? Map<String, dynamic>.from(rawUser) : null;
    final studentName = user?['name'] ?? "Student";

    final screens = [
      HomeScreen(
        user: user,
        onTabChange: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
      ),
      const HomeworkScreen(),
      const NotificationScreen(),
      MenuScreen(onLogout: _logoutUser),
      const AttendanceScreen(),
      const FeesScreen(),
      const LeaveScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        // Show exit confirmation dialog
        final shouldExit = await _showExitDialog(context);
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: TopNavBar(
          studentName: studentName,
          onProfileTap: () => _onNavigate(0),
          onToggleTheme: widget.onToggleTheme,
        ),
        body: PageView(
          controller: _pageController,
          physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: screens,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavigate,
        ),
      ),
    );
  }
}
