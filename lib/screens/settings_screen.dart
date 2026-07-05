import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen allowing the user to configure preferences, primarily their daily step goal.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  bool _isLoading = true;

  // Preset steps recommendations for fast configuration
  final List<int> _presets = [5000, 8000, 10000, 12000, 15000];

  @override
  void initState() {
    super.initState();
    _loadCurrentGoal();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  /// Loads current daily step goal from SharedPreferences (defaults to 10000).
  Future<void> _loadCurrentGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final currentGoal = prefs.getInt('daily_step_goal') ?? 10000;
    setState(() {
      _goalController.text = currentGoal.toString();
      _isLoading = false;
    });
  }

  /// Saves the step goal to SharedPreferences.
  Future<void> _saveGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_step_goal', goal);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Daily step goal updated to ${goal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Refresh UI to match the new text in form field
    setState(() {
      _goalController.text = goal.toString();
    });
  }

  /// Trigger form validation and save custom goal input.
  void _submitCustomGoal() {
    if (!_formKey.currentState!.validate()) return;
    final val = int.parse(_goalController.text);
    _saveGoal(val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Goal Section Card
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
                            Row(
                              children: [
                                Icon(
                                  Icons.track_changes,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Daily Goals',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Set a custom target for the number of steps you want to complete each day. Regular activity helps maintain health.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Form Input
                            TextFormField(
                              controller: _goalController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Daily Step Goal',
                                prefixIcon: const Icon(Icons.directions_run_outlined),
                                suffixText: 'steps',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a step goal';
                                }
                                final val = int.tryParse(value);
                                if (val == null || val <= 0) {
                                  return 'Step goal must be a positive integer';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitCustomGoal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Goal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Presets
                    Text(
                      'Quick Presets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _presets.map((preset) {
                        final formattedPreset = preset.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        );
                        final isSelected = _goalController.text == preset.toString();

                        return ChoiceChip(
                          label: Text('$formattedPreset steps'),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
                            if (selected) {
                              _saveGoal(preset);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 48),

                    // App Info / Branding Card
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'CodeAlpha Internship Project',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Fitness Tracker App v1.0.0',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
