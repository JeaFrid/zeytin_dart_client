extension ZeytinDateExtension on DateTime {
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inDays > 7) {
      return "$day/$month/$year";
    } else if (diff.inDays >= 1) {
      return "${diff.inDays} days ago";
    } else if (diff.inHours >= 1) {
      return "${diff.inHours} hours ago";
    } else {
      return "Just now";
    }
  }
}
