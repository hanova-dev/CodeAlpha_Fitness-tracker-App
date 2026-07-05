# AuraFit - Premium Personal Fitness Tracker

A modern, feature-rich, and premium personal Fitness Tracker mobile application built with **Flutter (Material 3)**. This application was designed and implemented for the **CodeAlpha Mobile Application Development Internship** submission.

AuraFit allows users to log workouts, track daily steps, monitor calories, review historical progress, and configure daily activity targets with a seamless, highly aesthetic light and dark mode experience.

---

## 🌟 Key Features

### 1. Dashboard (Home Screen)
*   **Step Goal Progress Ring**: A clean circular progress ring showing current progress towards the daily step goal, featuring percentage progress indicators.
*   **Stat Cards**: Individual interactive cards detailing today's total steps, total calories burned, and total active minutes, styled with specific background tints and vibrant icon colors.
*   **Weekly Analysis Chart**: An interactive bar chart built using `fl_chart`. It lets users toggle between **Steps** and **Calories** metrics over the last 7 calendar days.

### 2. Workout Logger (Add Activity Screen)
*   **Structured Form**: Log workouts by defining the activity type (dropdown: Walking, Running, Cycling, Gym, Yoga, Other).
*   **Calorie Estimation**: Automatically calculates a recommended calorie burn estimate based on selected activity type and duration, allowing manual edits.
*   **Integrated Pickers**: Custom date and time selectors (defaulting to the current local time) to log historical workouts.

### 3. Activity History
*   **Date Grouping**: Workout entries are logically categorized into clear daily timeline groups (e.g. *Today*, *Yesterday*, *Monday, July 6*).
*   **Swipe-to-Delete**: Native gesture support to swipe an entry to the left to delete it, with a handy Snackbar "Undo" action.
*   **Delete Button**: Accessible trash icons per card displaying verification dialog alerts to prevent accidental data loss.

### 4. Settings Configuration
*   **Custom Goal Editor**: Change the daily step target (e.g. 10,000 steps) with dynamic field validation.
*   **Goal Presets**: Fast goal modification chips (5k, 8k, 10k, 12k, and 15k steps) that save configurations instantly.

### 5. Premium Theme Mode
*   **Adaptive Theme System**: Supports Light and Dark modes matching the system UI preferences. High contrast, dark glassmorphism styling, and custom font weights.

---

## 🛠️ Tech Stack & Dependencies

*   **Framework**: Flutter & Dart (configured for Material 3)
*   **Local Storage**:
    *   `sqflite`: Handles SQLite databases for high-speed CRUD storage of activity logs.
    *   `shared_preferences`: Saves configuration metrics (daily step goals) persistently.
*   **Data Visualization**: `fl_chart` for responsive bar charts.
*   **Formatting**: `intl` for datetime formats and number comma styling (e.g. `10,000`).
*   **Platform Utils**: `path` for safe, platform-independent database directories.

---

## 📂 Project Architecture

The codebase follows a modular structure to enforce separation of concerns:

```
lib/
├── models/
│   └── fitness_entry.dart      # Data model & JSON/Map serialization
├── services/
│   └── database_service.dart   # SQLite database operations & custom statistics queries
├── widgets/
│   ├── stat_card.dart          # Today's activity metric card
│   └── weekly_chart.dart       # Toggleable bar chart for weekly steps/calories
├── screens/
│   ├── home_screen.dart        # Main dashboard screen
│   ├── add_entry_screen.dart   # Manual logging form
│   ├── history_screen.dart     # Grouped log feed with deletion gestures
│   └── settings_screen.dart    # Daily step goal editor & presets
└── main.dart                   # Application entry point, dark/light theme configs
```

---

## 🗄️ Database Design

AuraFit utilizes a persistent local SQLite table named `fitness_entries` containing the following schema:

| Column Name | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Auto-incrementing identifier |
| `activity_type` | `TEXT` | `NOT NULL` | Dropdown value selected by user |
| `duration` | `INTEGER` | `NOT NULL` | Duration of activity in minutes |
| `steps` | `INTEGER` | `NOT NULL` | Number of steps taken |
| `calories` | `INTEGER` | `NOT NULL` | Calories burned (kcal) |
| `date_time` | `TEXT` | `NOT NULL` | Saved as ISO8601 string |

---

## 🚀 Getting Started

### Prerequisites
Make sure you have Flutter installed and configured. Verify your development environment:
```bash
flutter doctor
```

### Installation
1.  Clone this repository or extract the project files into your workspace.
2.  Navigate to the directory:
    ```bash
    cd "Fitness Tracker App"
    ```
3.  Install packages:
    ```bash
    flutter pub get
    ```

### Running the App
Run on a connected emulator, simulator, or developer-enabled device:
```bash
flutter run
```

### Running Tests
Execute the unit and widget tests:
```bash
flutter test
```
Outputs from the test suite:
```
FitnessEntry Model Unit Tests:
  ✓ should create a valid FitnessEntry instance
  ✓ should serialize to Map correctly
  ✓ should deserialize from Map correctly
StatCard Widget Tests:
  ✓ should render title, value and unit in the card

All tests passed!
```
