/// Notification/Communication model
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String date;
  final String? category;
  final String? type;
  final String readStatus;
  final String ackStatus;
  final String? senderName;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.category,
    this.type,
    this.readStatus = 'UNREAD',
    this.ackStatus = 'PENDING',
    this.senderName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      date: json['date'] as String? ?? 
            json['created_at'] as String? ?? 
            DateTime.now().toIso8601String(),
      category: json['category'] as String?,
      type: json['type'] as String?,
      readStatus: json['read_status'] as String? ?? 'UNREAD',
      ackStatus: json['ack_status'] as String? ?? 'PENDING',
      senderName: json['sender_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'date': date,
      'category': category,
      'type': type,
      'read_status': readStatus,
      'ack_status': ackStatus,
      'sender_name': senderName,
    };
  }

  bool get isRead => readStatus == 'READ';
  bool get isAcknowledged => ackStatus == 'ACKNOWLEDGED';
}

