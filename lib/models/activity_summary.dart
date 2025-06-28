// lib/models/activity_summary.dart

class ActivitySummary {
  final int totalActivities;
  final int activeActivities;
  final int completedActivities;
  final int upcomingActivities; // Added upcomingActivities

  ActivitySummary({
    required this.totalActivities,
    required this.activeActivities,
    required this.completedActivities,
    required this.upcomingActivities,
  });

  // Factory constructor to create an instance from a Map (e.g., from Firestore)
  factory ActivitySummary.fromMap(Map<String, dynamic> map) {
    return ActivitySummary(
      totalActivities: map['totalActivities'] as int? ?? 0,
      activeActivities: map['activeActivities'] as int? ?? 0,
      completedActivities: map['completedActivities'] as int? ?? 0,
      upcomingActivities: map['upcomingActivities'] as int? ?? 0,
    );
  }

  // Method to convert an instance to a Map (e.g., for Firestore)
  Map<String, dynamic> toMap() => {
        'totalActivities': totalActivities,
        'activeActivities': activeActivities,
        'completedActivities': completedActivities,
        'upcomingActivities': upcomingActivities,
      };
}
