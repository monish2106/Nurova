class SessionModel {
  final DateTime startTime;
  final Duration currentDuration;
  final double screenTimeHours;
  final int moodScore;
  final double timeOfDay;

  SessionModel({
    required this.startTime,
    required this.currentDuration,
    required this.screenTimeHours,
    required this.moodScore,
    required this.timeOfDay,
  });

  String get formattedDuration {
    final h = currentDuration.inHours;
    final m = currentDuration.inMinutes % 60;
    final s = currentDuration.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  Map<String, dynamic> toFeatures() => {
    'screen_time': screenTimeHours,
    'distraction_freq': (screenTimeHours * 3.5).round().clamp(0, 50),
    'mood_score': moodScore,
    'goal_alignment_score': moodScore / 10.0,
    'task_completion_rate': (10 - moodScore) / 10.0 * 0.6 + 0.2,
    'time_of_day': timeOfDay,
    'hour_of_session': currentDuration.inHours.clamp(0, 24),
  };
}
