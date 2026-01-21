import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/event_service.dart';
import '../core/utils/error_handler.dart';
import '../presentation/core/widgets/error_widget.dart' as error_widget;
import '../presentation/core/widgets/empty_state_widget.dart';
import '../presentation/core/widgets/loading_indicator.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<dynamic> _events = [];
  bool _loading = true;
  String? _errorMessage;
  String? _errorCode;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents({bool refresh = false}) async {
    if (refresh) {
      _events.clear();
      _errorMessage = null;
      _errorCode = null;
    }

    setState(() {
      _loading = true;
      if (refresh) {
        _errorMessage = null;
        _errorCode = null;
      }
    });

    try {
      final res = await _eventService.getEvents();
      if (!mounted) return;

      final result = ErrorHandler.handleApiResponse(res);

      if (result.success) {
        final data = ErrorHandler.extractList(result.data);

        setState(() {
          _loading = false;
          _events = data;
          _errorMessage = null;
          _errorCode = null;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = result.message;
          _errorCode = result.errorCode;
        });

        ErrorHandler.logError(
          context: 'EventsScreen._loadEvents',
          error: result.message,
          additionalInfo: {'errorCode': result.errorCode},
        );
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      final message = ErrorHandler.getErrorMessage(e);
      final code = ErrorHandler.getErrorCode(e);

      ErrorHandler.logError(
        context: 'EventsScreen._loadEvents',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        _loading = false;
        _errorMessage = message;
        _errorCode = code;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Date TBA';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getEventTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'sports':
        return Colors.green;
      case 'academic':
        return Colors.blue;
      case 'cultural':
        return Colors.purple;
      case 'meeting':
        return Colors.orange;
      case 'competition':
        return Colors.red;
      case 'field trip':
        return Colors.teal;
      case 'exhibition':
        return Colors.pink;
      case 'fair':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer;
      case 'academic':
        return Icons.school;
      case 'cultural':
        return Icons.music_note;
      case 'meeting':
        return Icons.people;
      case 'competition':
        return Icons.emoji_events;
      case 'field trip':
        return Icons.directions_bus;
      case 'exhibition':
        return Icons.palette;
      case 'fair':
        return Icons.store;
      default:
        return Icons.event;
    }
  }

  Widget _buildEventCard(dynamic event) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventType = event['event_type'] ?? 'Event';
    final eventTypeColor = _getEventTypeColor(eventType);
    final eventIcon = _getEventTypeIcon(eventType);
    final eventDate = _formatDate(event['event_date']);
    final eventTime = event['event_time'] ?? 'Time TBA';
    final eventLocation = event['event_location'] ?? 'Location TBA';
    final eventImage = event['event_image'];
    final isRegistrationRequired = event['is_registration_required'] == true;
    final registrationDeadline = event['registration_deadline'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (eventImage != null && eventImage.toString().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    eventImage.toString(),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          eventIcon,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                  // Event Type Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: eventTypeColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            eventIcon,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            eventType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: eventTypeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  eventIcon,
                  size: 64,
                  color: eventTypeColor,
                ),
              ),
            ),

          // Event Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  event['event_title'] ?? 'Event',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Event Description
                if (event['event_description'] != null)
                  Text(
                    event['event_description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),

                // Event Details
                _buildDetailRow(
                  Icons.calendar_today,
                  eventDate,
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.access_time,
                  eventTime,
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.location_on,
                  eventLocation,
                  colorScheme,
                ),

                // Registration Info
                if (isRegistrationRequired) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            registrationDeadline != null
                                ? 'Registration required. Deadline: ${_formatDate(registrationDeadline)}'
                                : 'Registration required',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.events),
        elevation: 0,
      ),
      body: _loading && _events.isEmpty && _errorMessage == null
          ? LoadingIndicator(message: 'Loading events...')
          : _errorMessage != null && _events.isEmpty
              ? error_widget.CustomErrorWidget(
                  message: _errorMessage!,
                  errorCode: _errorCode,
                  onRetry: () => _loadEvents(refresh: true),
                )
              : _events.isEmpty
                  ? EmptyStateWidget(
                      message: 'No events available',
                      icon: Icons.event_busy,
                      actionLabel: 'Retry',
                      onAction: () => _loadEvents(refresh: true),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadEvents(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(_events[index]);
                        },
                      ),
                    ),
    );
  }
}

