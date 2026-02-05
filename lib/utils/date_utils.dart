import 'package:intl/intl.dart';

class RelativeDateUtils {
  /// Formats a date relative to today (aujourd'hui, hier, or normal date)
  static String formatRelativeDate(DateTime date, {String? locale}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Check if date is today
    if (dateOnly.isAtSameMomentAs(today)) {
      return "Aujourd'hui";
    }
    
    // Check if date is yesterday
    if (dateOnly.isAtSameMomentAs(yesterday)) {
      return "Hier";
    }
    
    // For older dates, return formatted date
    if (dateOnly.isBefore(yesterday)) {
      return DateFormat('dd MMMM yyyy', locale ?? 'fr_FR').format(date);
    }
    
    // For future dates (shouldn't happen often but just in case)
    return DateFormat('dd MMMM yyyy', locale ?? 'fr_FR').format(date);
  }
  
  /// Formats date with time for detailed views
  static String formatRelativeDateWithTime(DateTime date, {String? locale}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final timeFormatter = DateFormat('HH:mm', locale ?? 'fr_FR');
    
    // Check if date is today
    if (dateOnly.isAtSameMomentAs(today)) {
      return "Aujourd'hui à ${timeFormatter.format(date)}";
    }
    
    // Check if date is yesterday
    if (dateOnly.isAtSameMomentAs(yesterday)) {
      return "Hier à ${timeFormatter.format(date)}";
    }
    
    // For older dates, return formatted date with time
    if (dateOnly.isBefore(yesterday)) {
      return "${DateFormat('dd MMM', locale ?? 'fr_FR').format(date)} à ${timeFormatter.format(date)}";
    }
    
    // For future dates
    return "${DateFormat('dd MMM', locale ?? 'fr_FR').format(date)} à ${timeFormatter.format(date)}";
  }
  
  /// Formats date for list items (compact format)
  static String formatCompactDate(DateTime date, {String? locale}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Check if date is today
    if (dateOnly.isAtSameMomentAs(today)) {
      return "Aujourd'hui";
    }
    
    // Check if date is yesterday
    if (dateOnly.isAtSameMomentAs(yesterday)) {
      return "Hier";
    }
    
    // For this week (within 7 days), show day name
    final daysDiff = today.difference(dateOnly).inDays;
    if (daysDiff <= 7 && daysDiff > 1) {
      return DateFormat('EEEE', locale ?? 'fr_FR').format(date);
    }
    
    // For older dates, show compact date
    if (dateOnly.year == today.year) {
      return DateFormat('dd MMM', locale ?? 'fr_FR').format(date);
    } else {
      return DateFormat('dd/MM/yy', locale ?? 'fr_FR').format(date);
    }
  }
}