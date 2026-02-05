class RecurringTransaction {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String? description;
  final String type; // 'expense' or 'income'
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int currentOccurrences;
  final DateTime nextDueDate;
  final bool isActive;

  RecurringTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.description,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.currentOccurrences = 0,
    required this.nextDueDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'type': type,
      'frequency': frequency,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'max_occurrences': maxOccurrences,
      'current_occurrences': currentOccurrences,
      'next_due_date': nextDueDate.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  static RecurringTransaction fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      description: map['description'],
      type: map['type'],
      frequency: map['frequency'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date']),
      endDate: map['end_date'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['end_date'])
        : null,
      maxOccurrences: map['max_occurrences'],
      currentOccurrences: map['current_occurrences'] ?? 0,
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['next_due_date']),
      isActive: map['is_active'] == 1,
    );
  }

  RecurringTransaction copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    String? description,
    String? type,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
    int? currentOccurrences,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      currentOccurrences: currentOccurrences ?? this.currentOccurrences,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Calculate the next due date based on current date and frequency
  DateTime calculateNextDueDate([DateTime? fromDate]) {
    final baseDate = fromDate ?? nextDueDate;
    
    switch (frequency) {
      case 'daily':
        return DateTime(baseDate.year, baseDate.month, baseDate.day + 1);
      case 'weekly':
        return DateTime(baseDate.year, baseDate.month, baseDate.day + 7);
      case 'monthly':
        final nextMonth = baseDate.month == 12 ? 1 : baseDate.month + 1;
        final nextYear = baseDate.month == 12 ? baseDate.year + 1 : baseDate.year;
        return DateTime(nextYear, nextMonth, baseDate.day);
      case 'yearly':
        return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
      default:
        return baseDate;
    }
  }

  /// Check if this recurring transaction should generate a new transaction today
  bool shouldGenerateToday() {
    if (!isActive) return false;
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueDateOnly = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    
    // Check if today is the due date or later
    if (todayOnly.isBefore(dueDateOnly)) return false;
    
    // Check if we've reached max occurrences
    if (maxOccurrences != null && currentOccurrences >= maxOccurrences!) return false;
    
    // Check if we've passed the end date
    if (endDate != null && todayOnly.isAfter(endDate!)) return false;
    
    return true;
  }

  /// Get frequency display text
  String get frequencyDisplayText {
    switch (frequency) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      default:
        return frequency;
    }
  }

  /// Get type display text
  String get typeDisplayText {
    switch (type) {
      case 'expense':
        return 'Dépense';
      case 'income':
        return 'Revenu';
      default:
        return type;
    }
  }

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, title: $title, amount: $amount, type: $type, frequency: $frequency, nextDue: $nextDueDate)';
  }
}