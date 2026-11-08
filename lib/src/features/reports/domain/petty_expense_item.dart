/// بند مصروفات نثرية من الخزينة والدرج اليومي (Petty Cash Item)
class PettyExpenseItem {
  final String id;
  final String title;
  final double amount;
  final DateTime time;

  const PettyExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'time': time.toIso8601String(),
      };

  Map<String, dynamic> toJson() => toMap();

  factory PettyExpenseItem.fromMap(Map<String, dynamic> map) {
    return PettyExpenseItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      time: map['time'] != null ? DateTime.tryParse(map['time'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  factory PettyExpenseItem.fromJson(Map<String, dynamic> json) =>
      PettyExpenseItem.fromMap(json);
}
