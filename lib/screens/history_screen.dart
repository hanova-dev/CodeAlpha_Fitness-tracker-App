import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fitness_entry.dart';
import '../services/database_service.dart';
import 'add_entry_screen.dart';

/// Screen listing all logged activities grouped by date, supporting deletions.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dbService = DatabaseService();
  List<FitnessEntry> _entries = [];
  bool _isLoading = true;

  // Colors & Icons config matching activities
  final Map<String, Map<String, dynamic>> _activityConfig = {
    'Walking': {'icon': Icons.directions_walk, 'color': Colors.green},
    'Running': {'icon': Icons.directions_run, 'color': Colors.teal},
    'Cycling': {'icon': Icons.directions_bike, 'color': Colors.indigo},
    'Gym': {'icon': Icons.fitness_center, 'color': Colors.deepOrange},
    'Yoga': {'icon': Icons.self_improvement, 'color': Colors.pink},
    'Other': {'icon': Icons.more_horiz, 'color': Colors.blueGrey},
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  /// Reload logged activities from sqlite.
  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await _dbService.getAllEntries();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  /// Deletes a logged entry from database.
  Future<void> _deleteEntry(FitnessEntry entry) async {
    if (entry.id == null) return;
    
    // Optimistic UI updates
    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
    });

    try {
      await _dbService.deleteEntry(entry.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.activityType} workout deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.amber,
            onPressed: () async {
              // Insert back to database
              await _dbService.insertEntry(entry);
              _loadEntries();
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete log: $e')),
      );
      _loadEntries(); // revert on failure
    }
  }

  /// Helper to get a human-readable date header (e.g. "Today", "Yesterday").
  String _getDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Grouping the entries by date. We create a map of DateHeader string -> List of fitness entries.
    final Map<String, List<FitnessEntry>> groupedEntries = {};
    for (var entry in _entries) {
      final header = _getDateHeader(entry.dateTime);
      if (groupedEntries[header] == null) {
        groupedEntries[header] = [];
      }
      groupedEntries[header]!.add(entry);
    }

    // Convert map to sequential list of items to display (headers & entries)
    final List<dynamic> listItems = [];
    groupedEntries.forEach((header, entries) {
      listItems.add(header); // String
      listItems.addAll(entries); // FitnessEntry
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntries,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : listItems.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    final item = listItems[index];

                    // If it is a date group header
                    if (item is String) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 20.0, bottom: 8.0),
                        child: Text(
                          item,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }

                    // Otherwise, it is a FitnessEntry
                    final entry = item as FitnessEntry;
                    final config = _activityConfig[entry.activityType] ?? {
                      'icon': Icons.fitness_center,
                      'color': theme.colorScheme.secondary,
                    };
                    final Color color = config['color'] as Color;

                    return Dismissible(
                      key: Key(entry.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (_) => _deleteEntry(entry),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.12),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              config['icon'] as IconData,
                              color: color,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            entry.activityType,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('${entry.duration} mins'),
                                  const SizedBox(width: 12),
                                  Icon(Icons.local_fire_department_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text('${entry.calories} kcal'),
                                  if (entry.steps > 0) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.directions_walk_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text('${entry.steps} steps'),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('h:mm a').format(entry.dateTime),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                            onPressed: () => _showDeleteConfirmation(context, entry),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  /// Show delete confirmation dialog to protect accidental deletion.
  Future<void> _showDeleteConfirmation(BuildContext context, FitnessEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: Text('Are you sure you want to delete this ${entry.activityType} workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteEntry(entry);
    }
  }

  /// Visual placeholder when history is empty.
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No workouts logged yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your logged activities will appear here grouped by day. Start logging to track your progression!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEntryScreen()),
                );
                if (result == true) {
                  _loadEntries();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Log First Workout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
