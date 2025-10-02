class DateFormatter {
  /// Formats a DateTime into a human-readable "time ago" string
  /// Handles timezone differences and prevents negative time display
  /// Uses consistent format: just now, minutes, hours, days, weeks, months, years
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    
    // Convert both to UTC to avoid timezone issues
    final nowUtc = now.toUtc();
    final dateTimeUtc = dateTime.toUtc();
    
    final difference = nowUtc.difference(dateTimeUtc);
    
    // Handle future dates (shouldn't happen, but safety check)
    if (difference.isNegative) {
      return 'Just now';
    }
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours}h ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
}