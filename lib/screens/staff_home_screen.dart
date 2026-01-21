import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import 'package:html/parser.dart' as html_parser;
import '../presentation/core/widgets/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StaffHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final void Function(int)? onTabChange;

  const StaffHomeScreen({super.key, this.user, this.onTabChange});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  String todayStatus = "Present";
  String monthLOP = "Nil";
  bool _loading = true;
  bool _loadingAlerts = false;
  List<dynamic> _todayAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _loading = true);
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final now = DateTime.now();
      final monthYear = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      // Load staff attendance
      try {
        final data = await AttendanceService().getAttendance(monthYear);
        if (data != null) {
          final today = _formatDate(now);
          String status = '';

          if ((data['student_present_approved'] ?? []).contains(today)) {
            status = 'Present';
          } else if ((data['student_leaves'] ?? []).contains(today)) {
            status = 'Leave';
          } else if ((data['leave_days'] ?? []).contains(today)) {
            status = 'Holiday';
          } else if ((data['holidays'] ?? [])
              .any((h) => h['holiday_date'] == today)) {
            status = 'Holiday';
          } else {
            status = 'Absent';
          }

          setState(() {
            todayStatus = status;
            // Calculate LOP (Loss of Pay) - this would come from API
            monthLOP = "Nil"; // Placeholder - should come from API
          });
        }
      } catch (e) {
        debugPrint('Error loading attendance: $e');
      }

      // Load today's alerts
      _loadTodayAlerts();

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading staff data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTodayAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final today = DateTime.now();
      final alerts = await NotificationService().getPostCommunications(
        fromDate: today,
        toDate: today,
      );
      if (mounted) {
        setState(() {
          _todayAlerts = alerts;
          _loadingAlerts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAlerts = false);
      }
    }
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _loading
          ? LoadingIndicator()
          : ValueListenableBuilder(
              valueListenable: Hive.box('settings').listenable(keys: ['user', 'pf_img_cb']),
              builder: (context, Box box, _) {
                final data = box.get('user', defaultValue: {}) as Map;
                final userDetails = data['userdetails'] ?? {};

                final String name = data['name']?.toString() ?? "Staff Member";
                final String mobile = data['mobile']?.toString() ?? "N/A";
                
                // Staff-specific fields (these would come from API)
                final String department = userDetails['department_name']?.toString() ?? 
                                        userDetails['is_department_name']?.toString() ?? 
                                        data['department']?.toString() ?? 
                                        "Dept. Maths";
                final String role = userDetails['role_name']?.toString() ?? 
                                  userDetails['is_role_name']?.toString() ?? 
                                  data['role']?.toString() ?? 
                                  "Teacher";
                final String empNo = userDetails['employee_no']?.toString() ?? 
                                   userDetails['emp_no']?.toString() ?? 
                                   data['employee_no']?.toString() ?? 
                                   data['main_ref_no']?.toString() ?? 
                                   "2025/M01";

                final int cb = box.get('pf_img_cb', defaultValue: 0) as int;
                final String rawImageUrl = (data['is_profile_image'] ??
                        "https://www.clasteqsms.com/multischool/public/image/default.png")
                    .toString();
                final String profileImage = "$rawImageUrl?cb=$cb";

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Staff Profile Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Photo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: profileImage,
                                width: 100,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 100,
                                  height: 120,
                                  color: colorScheme.primary.withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 100,
                                  height: 120,
                                  color: colorScheme.primary.withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Staff Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStaffDetailRow(
                                    'Dept.',
                                    department,
                                    colorScheme,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStaffDetailRow(
                                    'ROLE',
                                    role,
                                    colorScheme,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStaffDetailRow(
                                    'EMP. No',
                                    empNo,
                                    colorScheme,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStaffDetailRow(
                                    'CONTACT',
                                    mobile,
                                    colorScheme,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Staff Attendance Card
                      _buildStaffAttendanceCard(colorScheme, isDark),
                      const SizedBox(height: 12),

                      // Today's Alerts Card
                      _buildActionCard(
                        title: "TODAY'S ALERTS",
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onTap: () {
                          widget.onTabChange?.call(2); // Navigate to notifications
                        },
                        child: _buildAlertsPreview(colorScheme),
                      ),
                      const SizedBox(height: 12),

                      // Scholar Attendance Card
                      _buildActionCard(
                        title: "SCHOLAR ATTENDANCE",
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onTap: () {
                          widget.onTabChange?.call(4); // Navigate to attendance
                        },
                      ),
                      const SizedBox(height: 12),

                      // Fee Card
                      _buildActionCard(
                        title: "FEE",
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onTap: () {
                          widget.onTabChange?.call(5); // Navigate to fees
                        },
                      ),
                      const SizedBox(height: 12),

                      // Homework Card
                      _buildActionCard(
                        title: "HOMEWORK",
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onTap: () {
                          widget.onTabChange?.call(1); // Navigate to homework
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStaffDetailRow(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffAttendanceCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "STAFF ATTENDANCE",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Status",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(todayStatus),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        todayStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Month's LOP",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(monthLOP == "Nil" ? "Present" : "Absent"),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        monthLOP,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required ColorScheme colorScheme,
    required bool isDark,
    VoidCallback? onTap,
    Widget? child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (child != null) ...[
                const SizedBox(height: 12),
                child,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsPreview(ColorScheme colorScheme) {
    if (_loadingAlerts) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_todayAlerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'No alerts for today',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _todayAlerts.take(2).map<Widget>((alert) {
        final title = alert['title'] ?? 'Untitled';
        final message = html_parser
                .parse(alert['message'] ?? '')
                .body
                ?.text
                .trim() ??
            '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message.length > 60 ? '${message.substring(0, 60)}...' : message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      case 'holiday':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}

