import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A premium weekly bar chart widget that displays steps or calories over the last 7 days.
/// Includes a metric toggle (Steps / Calories) and polished animations.
class WeeklyChart extends StatefulWidget {
  final List<Map<String, dynamic>> weeklyData;

  const WeeklyChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  bool _showSteps = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate maximum value to scale the Y axis properly
    double maxValue = 0;
    for (var data in widget.weeklyData) {
      final double val = _showSteps
          ? (data['steps'] as int).toDouble()
          : (data['calories'] as int).toDouble();
      if (val > maxValue) {
        maxValue = val;
      }
    }
    // Fallback if no logs
    if (maxValue == 0) maxValue = _showSteps ? 10000 : 2000;

    // Add some padding to the max value so bars don't touch the top
    final yAxisMax = maxValue * 1.15;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              // Segmented toggle button for Steps / Calories
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildToggleButton(
                      label: 'Steps',
                      isSelected: _showSteps,
                      onTap: () => setState(() => _showSteps = true),
                    ),
                    _buildToggleButton(
                      label: 'Calories',
                      isSelected: !_showSteps,
                      onTap: () => setState(() => _showSteps = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yAxisMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => theme.colorScheme.secondaryContainer,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = widget.weeklyData[group.x.toInt()]['date'] as DateTime;
                      final dateStr = DateFormat('MMM d').format(date);
                      final valueStr = rod.toY.round().toString();
                      final unit = _showSteps ? ' steps' : ' kcal';
                      return BarTooltipItem(
                        '$dateStr\n$valueStr$unit',
                        TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.weeklyData.length) {
                          return const SizedBox.shrink();
                        }
                        final date = widget.weeklyData[index]['date'] as DateTime;
                        final isToday = DateUtils.isSameDay(date, DateTime.now());
                        final label = isToday ? 'Today' : DateFormat.E().format(date);
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(widget.weeklyData.length, (index) {
                  final data = widget.weeklyData[index];
                  final double val = _showSteps
                      ? (data['steps'] as int).toDouble()
                      : (data['calories'] as int).toDouble();

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        gradient: LinearGradient(
                          colors: _showSteps
                              ? [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.7),
                                ]
                              : [
                                  Colors.orange,
                                  Colors.orange.withOpacity(0.7),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: yAxisMax,
                          color: theme.colorScheme.outlineVariant.withOpacity(0.12),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
