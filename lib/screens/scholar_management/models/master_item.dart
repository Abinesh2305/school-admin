class MasterItem {
  final int id;
  final String name;
  final bool isActive;
  late int sortOrder;
  

  MasterItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
  });

  factory MasterItem.fromJson(Map<String, dynamic> json) {
  return MasterItem(
    id: json['id'],
    name: json['name'],
    isActive: json['isActive'],
    sortOrder: json['sortOrder'] ?? 0, 
  );
}

}
