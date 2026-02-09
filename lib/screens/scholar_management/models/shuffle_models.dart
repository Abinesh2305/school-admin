class ShufflePreview {
  final int totalSelected;
  final int eligibleCount;
  final int ineligibleCount;
  final List<ShufflePreviewItem> items;

  ShufflePreview({
    required this.totalSelected,
    required this.eligibleCount,
    required this.ineligibleCount,
    required this.items,
  });

  factory ShufflePreview.fromJson(Map<String, dynamic> json) {
    return ShufflePreview(
      totalSelected: json['totalSelected'],
      eligibleCount: json['eligibleCount'],
      ineligibleCount: json['ineligibleCount'],
      items: (json['items'] as List)
          .map((e) => ShufflePreviewItem.fromJson(e))
          .toList(),
    );
  }
}

class ShufflePreviewItem {
  final int studentId;
  final String admissionNo;
  final String name;
  final bool canMove;
  final String? message;

  ShufflePreviewItem({
    required this.studentId,
    required this.admissionNo,
    required this.name,
    required this.canMove,
    this.message,
  });

  factory ShufflePreviewItem.fromJson(Map<String, dynamic> json) {
    return ShufflePreviewItem(
      studentId: json['studentId'],
      admissionNo: json['admissionNo'],
      name: json['name'],
      canMove: json['canMove'],
      message: json['message'],
    );
  }
}
class ShuffleBatch {
  final int id;
  final String status;
  final int totalSelected;
  final int movedCount;
  final int skippedCount;

  ShuffleBatch({
    required this.id,
    required this.status,
    required this.totalSelected,
    required this.movedCount,
    required this.skippedCount,
  });

  factory ShuffleBatch.fromJson(Map<String, dynamic> json) {
    return ShuffleBatch(
      id: json['id'] ?? json['batchId'],
      status: json['status'],
      totalSelected: json['totalSelected'] ?? 0,
      movedCount: json['movedCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
    );
  }
}

class ShuffleItem {
  final int id;
  final int studentId;
  final String admissionNo;
  final String status;
  final String? message;

  ShuffleItem({
    required this.id,
    required this.studentId,
    required this.admissionNo,
    required this.status,
    this.message,
  });

  factory ShuffleItem.fromJson(Map<String, dynamic> json) {
    return ShuffleItem(
      id: json['id'],
      studentId: json['studentId'],
      admissionNo: json['admissionNo'],
      status: json['status'],
      message: json['message'],
    );
  }
}
