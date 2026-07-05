import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker_app/models/fitness_entry.dart';
import 'package:fitness_tracker_app/widgets/stat_card.dart';

void main() {
  group('FitnessEntry Model Unit Tests', () {
    test('should create a valid FitnessEntry instance', () {
      final dateTime = DateTime.parse('2026-07-05T16:00:00Z');
      final entry = FitnessEntry(
        id: 1,
        activityType: 'Running',
        duration: 30,
        steps: 4000,
        calories: 330,
        dateTime: dateTime,
      );

      expect(entry.id, 1);
      expect(entry.activityType, 'Running');
      expect(entry.duration, 30);
      expect(entry.steps, 4000);
      expect(entry.calories, 330);
      expect(entry.dateTime, dateTime);
    });

    test('should serialize to Map correctly', () {
      final dateTime = DateTime.parse('2026-07-05T16:00:00Z');
      final entry = FitnessEntry(
        id: 2,
        activityType: 'Yoga',
        duration: 45,
        steps: 0,
        calories: 180,
        dateTime: dateTime,
      );

      final map = entry.toMap();

      expect(map['id'], 2);
      expect(map['activity_type'], 'Yoga');
      expect(map['duration'], 45);
      expect(map['steps'], 0);
      expect(map['calories'], 180);
      expect(map['date_time'], '2026-07-05T16:00:00.000Z');
    });

    test('should deserialize from Map correctly', () {
      final map = {
        'id': 3,
        'activity_type': 'Cycling',
        'duration': 60,
        'steps': 0,
        'calories': 480,
        'date_time': '2026-07-05T16:30:00.000Z',
      };

      final entry = FitnessEntry.fromMap(map);

      expect(entry.id, 3);
      expect(entry.activityType, 'Cycling');
      expect(entry.duration, 60);
      expect(entry.steps, 0);
      expect(entry.calories, 480);
      expect(entry.dateTime, DateTime.parse('2026-07-05T16:30:00.000Z'));
    });
  });

  group('StatCard Widget Tests', () {
    testWidgets('should render title, value and unit in the card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total steps',
              value: '8,420',
              icon: Icons.directions_walk,
              iconColor: Colors.green,
              backgroundColor: Colors.white,
              unit: 'steps',
            ),
          ),
        ),
      );

      // Verify widget values appear on screen
      expect(find.text('Total steps'), findsOneWidget);
      expect(find.text('8,420'), findsOneWidget);
      expect(find.text('steps'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    });
  });
}
