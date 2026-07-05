import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/weekly_chart.dart';
import 'add_entry_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// The main dashboard screen showing today's stats, step goal progress, and weekly analysis.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService();
  
  // State variables
  int _stepGoal = 10000;
  int _todaySteps = 0;
  int _todayCalories = 0;
  int _todayMinutes = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Fetch stats and goal settings concurrently to build the dashboard.
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    // Load step goal
    final prefs = await SharedPreferences.getInstance();
    _stepGoal = prefs.getInt('daily_step_goal') ?? 10000;

    // Load today's stats
    final todayStats = await _dbService.getTodayStats();
    _todaySteps = todayStats['steps'] ?? 0;
    _todayCalories = todayStats['calories'] ?? 0;
    _todayMinutes = todayStats['duration'] ?? 0;

    // Load weekly stats
    _weeklyData = await _dbService.getWeeklyStats();

    setState(() => _isLoading = false);
  }

  /// Formats numbers with commas (e.g. 10000 -> 10,000)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double stepProgress = (_todaySteps / _stepGoal).clamp(0.0, 1.0);
    final int percentComplete = (stepProgress * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'AuraFit Tracker',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'History',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
              _loadDashboardData(); // Refresh stats when returning
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadDashboardData(); // Refresh goal when returning
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Motivation Quote & Greeting
                    Text(
                      'Welcome back!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to crush your fitness goals today?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daily Step Goal Circular Progress Card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                        child: Column(
                          children: [
                            Text(
                              'Step Goal Progress',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Beautiful Stack with Circular Progress and text
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 170,
                                  height: 170,
                                  child: CircularProgressIndicator(
                                    value: stepProgress,
                                    strokeWidth: 14,
                                    backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                    color: theme.colorScheme.primary,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$percentComplete%',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Completed',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            // Current steps and Target steps text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      _formatNumber(_todaySteps),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Steps Taken',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      _formatNumber(_stepGoal),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Daily Goal',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's Stats Cards Grid
                    Text(
                      "Today's Activity Summary",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate width for responsive grid
                        final cardWidth = (constraints.maxWidth - 16) / 3;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: StatCard(
                                title: 'Steps',
                                value: _formatNumber(_todaySteps),
                                icon: Icons.directions_walk_rounded,
                                iconColor: Colors.green,
                                backgroundColor: Colors.green.withOpacity(0.04),
                                unit: 'steps',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: StatCard(
                                title: 'Calories',
                                value: _formatNumber(_todayCalories),
                                icon: Icons.local_fire_department_rounded,
                                iconColor: Colors.orange,
                                backgroundColor: Colors.orange.withOpacity(0.04),
                                unit: 'kcal',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: StatCard(
                                title: 'Minutes',
                                value: _todayMinutes.toString(),
                                icon: Icons.timer_rounded,
                                iconColor: Colors.teal,
                                backgroundColor: Colors.teal.withOpacity(0.04),
                                unit: 'mins',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Weekly Chart
                    WeeklyChart(weeklyData: _weeklyData),
                    const SizedBox(height: 80), // extra padding for scrolling past FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryScreen()),
          );
          if (success == true) {
            _loadDashboardData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
    );
  }
}
