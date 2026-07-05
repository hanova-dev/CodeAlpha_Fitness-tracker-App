/// Model class representing a single fitness activity logged by the user.
class FitnessEntry {
  final int? id;
  final String activityType; // Walking, Running, Cycling, Gym, Yoga, Other
  final int duration; // in minutes
  final int steps;
  final int calories;
  final DateTime dateTime;

  FitnessEntry({
    this.id,
    required this.activityType,
    required this.duration,
    required this.steps,
    required this.calories,
    required this.dateTime,
  });

  /// Convert a FitnessEntry instance into a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_type': activityType,
      'duration': duration,
      'steps': steps,
      'calories': calories,
      'date_time': dateTime.toIso8601String(),
    };
  }

  /// Reconstruct a FitnessEntry from a database map.
  factory FitnessEntry.fromMap(Map<String, dynamic> map) {
    return FitnessEntry(
      id: map['id'] as int?,
      activityType: map['activity_type'] as String,
      duration: map['duration'] as int,
      steps: map['steps'] as int,
      calories: map['calories'] as int,
      dateTime: DateTime.parse(map['date_time'] as String),
    );
  }

  /// Creates a copy of this FitnessEntry but with the given fields replaced with the new values.
  FitnessEntry copyWith({
    int? id,
    String? activityType,
    int? duration,
    int? steps,
    int? calories,
    DateTime? dateTime,
  }) {
    return FitnessEntry(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      duration: duration ?? this.duration,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}
