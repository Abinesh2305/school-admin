/// Homework model
class HomeworkModel {
  final int id;
  final String? mainRefNo;
  final String subject;
  final String description;
  final String date;
  final String? submissionDate;
  final List<String> attachments;
  final String readStatus;
  final String ackStatus;
  final int ackRequired;

  HomeworkModel({
    required this.id,
    this.mainRefNo,
    required this.subject,
    required this.description,
    required this.date,
    this.submissionDate,
    this.attachments = const [],
    this.readStatus = 'UNREAD',
    this.ackStatus = 'PENDING',
    this.ackRequired = 0,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'] as int,
      mainRefNo: json['main_ref_no'] as String?,
      subject: json['is_subject_name'] as String? ?? 
               json['subject'] as String? ?? '',
      description: json['hw_description'] as String? ?? 
                   json['description'] as String? ?? '',
      date: json['is_hw_date'] as String? ?? json['date'] as String? ?? '',
      submissionDate: json['is_hw_submission_date'] as String? ?? 
                      json['submissionDate'] as String?,
      attachments: (json['is_file_attachments'] as List<dynamic>?)
              ?.map((a) => a is Map 
                  ? (a['img'] ?? a['url']).toString()
                  : a.toString())
              .toList() ??
          [],
      readStatus: json['read_status'] as String? ?? 'UNREAD',
      ackStatus: json['ack_status'] as String? ?? 'PENDING',
      ackRequired: json['ack_required'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'main_ref_no': mainRefNo,
      'subject': subject,
      'description': description,
      'date': date,
      'submissionDate': submissionDate,
      'attachments': attachments,
      'read_status': readStatus,
      'ack_status': ackStatus,
      'ack_required': ackRequired,
    };
  }

  bool get isRead => readStatus == 'READ';
  bool get isAcknowledged => ackStatus == 'ACKNOWLEDGED';
}

