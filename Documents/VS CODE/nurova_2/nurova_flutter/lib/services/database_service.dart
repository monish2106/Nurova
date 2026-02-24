import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  static Future<void> initialize() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'nurova.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            screen_time_hours REAL,
            risk_probability REAL,
            mood_score INTEGER,
            personality_cluster TEXT,
            productive_minutes INTEGER,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE daily_metrics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            avg_risk REAL,
            total_screen_time REAL,
            sessions_count INTEGER,
            productivity_score REAL
          )
        ''');
      },
    );
  }

  static Future<void> saveSession({
    required double screenTimeHours,
    required double riskProbability,
    required int moodScore,
    required String personalityCluster,
    required int productiveMinutes,
  }) async {
    await _db?.insert('sessions', {
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'screen_time_hours': screenTimeHours,
      'risk_probability': riskProbability,
      'mood_score': moodScore,
      'personality_cluster': personalityCluster,
      'productive_minutes': productiveMinutes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getWeeklyData() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return await _db?.query(
          'sessions',
          where: 'date >= ?',
          whereArgs: [sevenDaysAgo.toIso8601String().substring(0, 10)],
          orderBy: 'date ASC',
        ) ??
        [];
  }

  static Future<Map<String, dynamic>> getDailyStats() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db?.query(
          'sessions',
          where: 'date = ?',
          whereArgs: [today],
        ) ??
        [];

    if (rows.isEmpty) {
      return {
        'avg_risk': 0.45,
        'total_screen_time': 2.5,
        'sessions_count': 1,
        'productivity_score': 0.62,
      };
    }

    double totalRisk = 0;
    double totalScreenTime = 0;
    for (final row in rows) {
      totalRisk += (row['risk_probability'] as num).toDouble();
      totalScreenTime += (row['screen_time_hours'] as num).toDouble();
    }

    return {
      'avg_risk': totalRisk / rows.length,
      'total_screen_time': totalScreenTime,
      'sessions_count': rows.length,
      'productivity_score': 1 - (totalRisk / rows.length),
    };
  }

  static Future<List<Map<String, dynamic>>> getHistoryForML() async {
    return await _db?.query('sessions', limit: 30, orderBy: 'created_at DESC') ?? [];
  }
}
