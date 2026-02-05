class Income {
  final int? id;
  final String title;
  final String? description;
  final double amount;
  final String category;
  final DateTime date;
  final int? accountId;

  Income({
    this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'account_id': accountId,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      accountId: map['account_id'],
    );
  }

  Income copyWith({
    int? id,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    int? accountId,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
    );
  }
}