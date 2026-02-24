class PredictionModel {
  final double riskProbability;
  final String action;
  final DateTime timestamp;

  PredictionModel({
    required this.riskProbability,
    required this.action,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  int get riskPercent => (riskProbability * 100).round();

  String get riskLabel {
    if (riskProbability > 0.75) return 'High Risk';
    if (riskProbability > 0.45) return 'Medium Risk';
    return 'Low Risk';
  }

  String get nudge {
    if (riskProbability > 0.85) return '🚨 Night Scroll detected! Time to close the app.';
    if (riskProbability > 0.75) return '⚠️ You\'re spiraling. One LeetCode = dopamine hit 🧠';
    if (riskProbability > 0.45) return '🌬️ Take a breath. 5 minutes of focus goes a long way.';
    return '✅ You\'re in the zone. Keep going!';
  }

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      riskProbability: (json['risk_prob'] as num).toDouble(),
      action: json['action'] as String,
    );
  }
}

class PersonalityModel {
  final String cluster;
  final List<String> traits;
  final String emoji;

  PersonalityModel({
    required this.cluster,
    required this.traits,
    required this.emoji,
  });

  String get displayName {
    switch (cluster) {
      case 'NightScrollAddict': return 'Night Scroll Addict';
      case 'StressScroller': return 'Stress Scroller';
      case 'ProcrastinationBinger': return 'Procrastination Binger';
      case 'ProductiveSprinter': return 'Productive Sprinter';
      default: return cluster;
    }
  }

  factory PersonalityModel.fromJson(Map<String, dynamic> json) {
    return PersonalityModel(
      cluster: json['cluster'] as String,
      traits: List<String>.from(json['traits'] as List),
      emoji: _emojiForCluster(json['cluster'] as String),
    );
  }

  static String _emojiForCluster(String c) {
    const map = {
      'NightScrollAddict': '🌙',
      'StressScroller': '😰',
      'ProcrastinationBinger': '📱',
      'ProductiveSprinter': '⚡',
    };
    return map[c] ?? '🤖';
  }
}

class ContentModel {
  final String title;
  final String url;
  final String thumbnail;
  final double score;
  final String channel;
  final String duration;

  ContentModel({
    required this.title,
    required this.url,
    required this.thumbnail,
    required this.score,
    required this.channel,
    required this.duration,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnail: json['thumbnail'] as String? ?? '',
      score: (json['score'] as num).toDouble(),
      channel: json['channel'] as String? ?? '',
      duration: json['duration'] as String? ?? '~10 min',
    );
  }
}
