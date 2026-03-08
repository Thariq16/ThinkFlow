import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

extension TimestampExtension on Timestamp? {
  /// Format as relative time (e.g., "2h ago", "3d ago")
  String get timeAgo {
    if (this == null) return '';
    final now = DateTime.now();
    final date = this!.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('MMM d').format(date);
  }

  /// Format as full date
  String get formattedDate {
    if (this == null) return '';
    return DateFormat('MMM d, yyyy').format(this!.toDate());
  }

  /// Format as date + time
  String get formattedDateTime {
    if (this == null) return '';
    return DateFormat('MMM d, yyyy h:mm a').format(this!.toDate());
  }
}

extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Convert snake_case to display name
  String get displayName {
    return split('_').map((w) => w.capitalize).join(' ');
  }

  /// Truncate to max length with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

extension DoubleExtension on double {
  /// Format as percentage string
  String get asPercent => '${(this * 100).round()}%';
}
