import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fitness_entry.dart';
import '../services/database_service.dart';

/// Screen allowing the user to manually log a new fitness activity.
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  // Form Fields
  String _selectedActivity = 'Walking';
  final _durationController = TextEditingController();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  // Activity list with corresponding icons and colors
  final List<Map<String, dynamic>> _activities = [
    {'name': 'Walking', 'icon': Icons.directions_walk, 'color': Colors.green},
    {'name': 'Running', 'icon': Icons.directions_run, 'color': Colors.teal},
    {'name': 'Cycling', 'icon': Icons.directions_bike, 'color': Colors.indigo},
    {'name': 'Gym', 'icon': Icons.fitness_center, 'color': Colors.deepOrange},
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'color': Colors.pink},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.blueGrey},
  ];

  @override
  void dispose() {
    _durationController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  /// Estimates calories based on activity and duration to help the user.
  void _updateCalorieEstimate() {
    final durationStr = _durationController.text;
    if (durationStr.isEmpty) return;

    final duration = int.tryParse(durationStr);
    if (duration == null || duration <= 0) return;

    int estimatePerMinute;
    switch (_selectedActivity) {
      case 'Walking':
        estimatePerMinute = 5;
        break;
      case 'Running':
        estimatePerMinute = 11;
        break;
      case 'Cycling':
        estimatePerMinute = 8;
        break;
      case 'Gym':
        estimatePerMinute = 7;
        break;
      case 'Yoga':
        estimatePerMinute = 4;
        break;
      default:
        estimatePerMinute = 6;
    }

    setState(() {
      _caloriesController.text = (duration * estimatePerMinute).toString();
    });
  }

  /// Automatically clears steps for activities where steps are not relevant.
  void _onActivityChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedActivity = newValue;
    });
    _updateCalorieEstimate();

    // If gym/yoga/other, steps might not make sense. We don't force, but we can default steps to 0.
    if (newValue != 'Walking' && newValue != 'Running') {
      _stepsController.text = '0';
    } else if (_stepsController.text == '0') {
      _stepsController.clear();
    }
  }

  /// Opens the date picker and time picker sequentially.
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  /// Validate and save entry to SQLite database.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.parse(_durationController.text);
    final steps = int.tryParse(_stepsController.text) ?? 0;
    final calories = int.parse(_caloriesController.text);

    final entry = FitnessEntry(
      activityType: _selectedActivity,
      duration: duration,
      steps: steps,
      calories: calories,
      dateTime: _selectedDateTime,
    );

    try {
      await _dbService.insertEntry(entry);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Successfully logged $_selectedActivity!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true); // Return true to signal home page to refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save log: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeActivity = _activities.firstWhere((a) => a['name'] == _selectedActivity);
    final Color activityColor = activeActivity['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Activity illustration header card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        activityColor.withOpacity(0.85),
                        activityColor.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: activityColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activeActivity['icon'] as IconData,
                          color: activityColor,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedActivity,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Estimate: ${_durationController.text.isNotEmpty ? _caloriesController.text : "0"} kcal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dropdown selection
                        DropdownButtonFormField<String>(
                          value: _selectedActivity,
                          decoration: InputDecoration(
                            labelText: 'Activity Type',
                            prefixIcon: Icon(activeActivity['icon'] as IconData, color: activityColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          items: _activities.map((activity) {
                            return DropdownMenuItem<String>(
                              value: activity['name'] as String,
                              child: Row(
                                children: [
                                  Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 20),
                                  const SizedBox(width: 12),
                                  Text(activity['name'] as String),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _onActivityChanged,
                        ),
                        const SizedBox(height: 20),

                        // Duration field
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Duration (Minutes)',
                            prefixIcon: const Icon(Icons.timer_outlined),
                            suffixText: 'mins',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter workout duration';
                            }
                            final val = int.tryParse(value);
                            if (val == null || val <= 0) {
                              return 'Duration must be greater than 0';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateCalorieEstimate(),
                        ),
                        const SizedBox(height: 20),

                        // Steps field
                        TextFormField(
                          controller: _stepsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Steps',
                            prefixIcon: const Icon(Icons.directions_walk_outlined),
                            helperText: _selectedActivity == 'Walking' || _selectedActivity == 'Running'
                                ? 'Highly recommended'
                                : 'Optional for this activity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final val = int.tryParse(value);
                              if (val == null || val < 0) {
                                return 'Steps cannot be negative';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Calories field
                        TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Calories Burned',
                            prefixIcon: const Icon(Icons.local_fire_department_outlined),
                            suffixText: 'kcal',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter calories burned';
                            }
                            final val = int.tryParse(value);
                            if (val == null || val < 0) {
                              return 'Calories cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Time Picker Tile
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      'Date & Time',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('EEEE, MMM d • h:mm a').format(_selectedDateTime),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () => _selectDateTime(context),
                      child: const Text('Change'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Save Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
