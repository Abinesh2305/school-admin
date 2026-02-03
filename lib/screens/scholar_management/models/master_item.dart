class MasterItem {
  final int id;
  final String name;
  final bool isActive;

  MasterItem({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory MasterItem.fromJson(Map<String, dynamic> json) {
    return MasterItem(
      id: json['id'],
      name: json['name'],
      isActive: json['isActive'],
    );
  }
}
