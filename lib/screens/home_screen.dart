import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import '../services/exam_service.dart';
import '../services/fees_service.dart';
import 'package:html/parser.dart' as html_parser;
import '../presentation/core/widgets/loading_indicator.dart';
import '../presentation/core/widgets/animated_card.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final void Function(int)? onTabChange;

  const HomeScreen({super.key, this.user, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double attendancePercent = 0.0;
  String todayStatus = "";
  bool _loading = true;
  String? _currentUserId;
  
  // Expandable sections state
  bool _alertsExpanded = false;
  bool _examsExpanded = false;
  bool _feesExpanded = false;
  
  // Data for expandable sections
  List<dynamic> _todayAlerts = [];
  List<dynamic> _exams = [];
  Map<String, dynamic>? _feesSummary;
  bool _loadingAlerts = false;
  bool _loadingExams = false;
  bool _loadingFees = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkUserAndReload();
  }

  void _checkUserAndReload() {
    final box = Hive.box('settings');
    final user = box.get('user');
    final newUserId = user?['id']?.toString();
    if (newUserId != _currentUserId) {
      _loadAttendanceData();
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      if (user == null) return;

      final now = DateTime.now();
      final monthYear = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      final data = await AttendanceService().getAttendance(monthYear);

      if (!mounted) return; // <-- IMPORTANT

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

        if (!mounted) return;
        setState(() {
          todayStatus = status;
          attendancePercent =
              double.tryParse(data['att_percentage'].toString()) ?? 0.0;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final settingsBox = Hive.box('settings');
    return Scaffold(
      body: _loading
          ? LoadingIndicator()
          : ValueListenableBuilder(
              valueListenable:
                  settingsBox.listenable(keys: ['user', 'pf_img_cb']),
              builder: (context, Box box, _) {
                final data = box.get('user', defaultValue: {}) as Map;
                final userDetails = data['userdetails'] ?? {};

                final String name = data['name']?.toString() ?? "Unknown";
                final String admissionNo =
                    data['admission_no']?.toString() ?? "N/A";
                final String mobile = data['mobile']?.toString() ?? "N/A";
                final String className =
                    userDetails['is_class_name']?.toString() ?? "N/A";
                final String section =
                    userDetails['is_section_name']?.toString() ?? "N/A";

                final int cb = box.get('pf_img_cb', defaultValue: 0) as int;

                final String rawImageUrl = (data['is_profile_image'] ??
                        "https://www.clasteqsms.com/multischool/public/image/default.png")
                    .toString();

                final String profileImage = "$rawImageUrl?cb=$cb";

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AnimatedCard(
                        index: 0,
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  profileImage,
                                  key: ValueKey(profileImage),
                                  width: 200,
                                  height: 250,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color:
                                          colorScheme.primary.withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: colorScheme.onSurface,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                        t.classLabel, className, colorScheme),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                        t.sectionLabel, section, colorScheme),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(t.admissionNoLabel,
                                        admissionNo, colorScheme),
                                    const SizedBox(height: 8),
                                    _buildDetailItem(
                                        t.contactLabel, mobile, colorScheme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedCard(
                        index: 1,
                        delay: const Duration(milliseconds: 100),
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                t.attendanceTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        t.todayStatus,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(todayStatus),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getStatusText(todayStatus, t),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        t.attendancePercentage,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "${attendancePercent.toStringAsFixed(1)}%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedCard(
                        index: 2,
                        delay: const Duration(milliseconds: 200),
                        child: _buildExpandableSection(
                          title: t.todayAlerts,
                          colorScheme: colorScheme,
                          isExpanded: _alertsExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _alertsExpanded = expanded;
                              if (expanded && _todayAlerts.isEmpty && !_loadingAlerts) {
                                _loadTodayAlerts();
                              }
                            });
                        },
                          child: _buildAlertsContent(colorScheme, t),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedCard(
                        index: 3,
                        delay: const Duration(milliseconds: 300),
                        child: _buildExpandableSection(
                          title: t.exams,
                          colorScheme: colorScheme,
                          isExpanded: _examsExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _examsExpanded = expanded;
                              if (expanded && _exams.isEmpty && !_loadingExams) {
                                _loadExams();
                              }
                            });
                          },
                          child: _buildExamsContent(colorScheme, t),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedCard(
                        index: 4,
                        delay: const Duration(milliseconds: 400),
                        child: _buildExpandableSection(
                          title: t.feeDetails,
                          colorScheme: colorScheme,
                          isExpanded: _feesExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _feesExpanded = expanded;
                              if (expanded && _feesSummary == null && !_loadingFees) {
                                _loadFees();
                              }
                            });
                          },
                          child: _buildFeesContent(colorScheme, t),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.orange;
      case 'Holiday':
        return Colors.blue;
      case 'Leave':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations t) {
    switch (status) {
      case 'Present':
        return t.present;
      case 'Absent':
        return t.leave;
      case 'Holiday':
        return t.holiday;
      case 'Leave':
        return t.absent;
      default:
        return '-';
    }
  }

  Widget _buildDetailItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required ColorScheme colorScheme,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.15),
                colorScheme.primary.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  Flexible(
                    child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                ),
              ),
              const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                color: colorScheme.primary,
              ),
                  ),
            ],
          ),
        ),
      ),
          if (isExpanded)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: child,
              ),
            ),
        ],
      ),
    );
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

  Future<void> _loadExams() async {
    setState(() => _loadingExams = true);
    try {
      final exams = await ExamService().getExamList();
      if (mounted) {
        setState(() {
          _exams = exams ?? [];
          _loadingExams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingExams = false);
      }
    }
  }

  Future<void> _loadFees() async {
    setState(() => _loadingFees = true);
    try {
      final batch = DateTime.now().year.toString();
      final fees = await FeesService().getScholarFeesPayments(batch);
      if (mounted) {
        setState(() {
          _feesSummary = fees;
          _loadingFees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFees = false);
      }
    }
  }

  Widget _buildAlertsContent(ColorScheme colorScheme, AppLocalizations t) {
    if (_loadingAlerts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_todayAlerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No alerts for today',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _todayAlerts.take(5).map<Widget>((alert) {
        final title = alert['title'] ?? 'Untitled';
        final message = html_parser
                .parse(alert['message'] ?? '')
                .body
                ?.text
                .trim() ??
            '';
        final date = alert['is_notify_datetime'] ?? alert['created_at'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message.length > 100 ? '${message.substring(0, 100)}...' : message,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExamsContent(ColorScheme colorScheme, AppLocalizations t) {
    if (_loadingExams) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_exams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No exams available',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _exams.take(5).map<Widget>((exam) {
        final examName = exam['exam_name'] ?? exam['name'] ?? 'Untitled';
        final examDate = exam['exam_date'] ?? exam['date'] ?? '';
        final term = exam['term_name'] ?? exam['term'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                examName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
              if (term.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Term: $term',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              if (examDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Date: $examDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeesContent(ColorScheme colorScheme, AppLocalizations t) {
    if (_loadingFees) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_feesSummary == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No fee details available',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    final data = _feesSummary!['data'] ?? {};
    final total = _feesSummary!['total'] ?? {};

    // Helper function to safely get list from data
    List<dynamic>? getFeeList(dynamic value) {
      if (value == null) return null;
      if (value is List) return value;
      return null;
    }

    final overdueFees = getFeeList(data['overdue_fees']);
    final dueFees = getFeeList(data['due_fees']);
    final pendingFees = getFeeList(data['pending_fees']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total is Map && total.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Fees:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '₹${total['total_fees'] ?? '0'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (overdueFees != null && overdueFees.isNotEmpty)
          _buildFeeSection('Overdue', overdueFees, Colors.red, colorScheme),
        if (dueFees != null && dueFees.isNotEmpty)
          _buildFeeSection('Due', dueFees, Colors.orange, colorScheme),
        if (pendingFees != null && pendingFees.isNotEmpty)
          _buildFeeSection('Pending', pendingFees, Colors.blueGrey, colorScheme),
      ],
    );
  }

  Widget _buildFeeSection(String title, List<dynamic> items, Color color, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...items.take(3).map<Widget>((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['fee_item']?['item_name'] ?? 'Fee Item',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '₹${item['balance_amount'] ?? '0'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
