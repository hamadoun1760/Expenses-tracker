class Budget {
  final int? id;
  final String category;
  final double amount;
  final String period; // 'monthly' or 'yearly'
  final DateTime createdDate;
  final DateTime? updatedDate;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.period,
    required this.createdDate,
    this.updatedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate?.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      period: map['period'],
      createdDate: DateTime.parse(map['created_date']),
      updatedDate: map['updated_date'] != null 
          ? DateTime.parse(map['updated_date']) 
          : null,
    );
  }

  Budget copyWith({
    int? id,
    String? category,
    double? amount,
    String? period,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}