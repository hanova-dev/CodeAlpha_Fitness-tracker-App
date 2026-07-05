import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/fitness_entry.dart';

/// Service to manage SQLite database operations for the Fitness Tracker app.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Getter for the database instance. Initialize if not already created.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the local SQLite database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// SQL query schema execution.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fitness_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_type TEXT NOT NULL,
        duration INTEGER NOT NULL,
        steps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        date_time TEXT NOT NULL
      )
    ''');
  }

  /// Insert a new fitness activity log.
  Future<int> insertEntry(FitnessEntry entry) async {
    final db = await database;
    return await db.insert('fitness_entries', entry.toMap());
  }

  /// Fetch all logged activities sorted by date/time (newest first).
  Future<List<FitnessEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_entries',
      orderBy: 'date_time DESC',
    );
    return List.generate(maps.length, (i) => FitnessEntry.fromMap(maps[i]));
  }

  /// Delete a log by its unique database ID.
  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete(
      'fitness_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get the sum of steps, calories, and duration for the current calendar day.
  Future<Map<String, int>> getTodayStats() async {
    final db = await database;
    final now = DateTime.now();
    // Use start of today in local time zone
    final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        SUM(steps) as total_steps,
        SUM(calories) as total_calories,
        SUM(duration) as total_duration
      FROM fitness_entries
      WHERE date_time >= ?
    ''', [startOfToday]);

    if (results.isEmpty || results[0]['total_steps'] == null) {
      return {
        'steps': 0,
        'calories': 0,
        'duration': 0,
      };
    }

    return {
      'steps': results[0]['total_steps'] as int? ?? 0,
      'calories': results[0]['total_calories'] as int? ?? 0,
      'duration': results[0]['total_duration'] as int? ?? 0,
    };
  }

  /// Fetch and aggregate fitness stats for the last 7 calendar days (including today).
  /// Returns a list of maps, containing the Date, total steps, and total calories for that day.
  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await database;
    final now = DateTime.now();
    // Retrieve entries from 7 days ago until now
    final startOfRange = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6))
        .toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'fitness_entries',
      where: 'date_time >= ?',
      whereArgs: [startOfRange],
    );

    final entries = List.generate(maps.length, (i) => FitnessEntry.fromMap(maps[i]));

    // Construct exactly 7 days of historical stats
    final List<Map<String, dynamic>> weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayEntries = entries.where((e) =>
          e.dateTime.year == day.year &&
          e.dateTime.month == day.month &&
          e.dateTime.day == day.day);

      int totalSteps = 0;
      int totalCalories = 0;
      for (var e in dayEntries) {
        totalSteps += e.steps;
        totalCalories += e.calories;
      }

      weeklyData.add({
        'date': day,
        'steps': totalSteps,
        'calories': totalCalories,
      });
    }

    return weeklyData;
  }
}
