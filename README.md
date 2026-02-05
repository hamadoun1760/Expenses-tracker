# Expense Tracker

A professional Flutter application for tracking personal expenses with features to create, edit, and delete expenses.

## Features

- ✅ **Add New Expenses**: Create expenses with title, amount, category, date, and optional description
- ✅ **Edit Existing Expenses**: Modify any expense details
- ✅ **Delete Expenses**: Remove unwanted expenses with confirmation
- ✅ **Category Management**: 11 predefined categories with custom icons and colors
- ✅ **Statistics Dashboard**: View expense breakdowns by category and month
- ✅ **Professional UI**: Modern Material Design 3 interface
- ✅ **Filtering**: Filter expenses by category
- ✅ **Local Storage**: Data persisted using SQLite database
- ✅ **Date Selection**: Easy date picker for expense dates
- ✅ **Total Tracking**: Real-time total expense calculation

## Categories

The app includes the following expense categories:
- 🍽️ Food & Dining
- 🚗 Transportation  
- 🛍️ Shopping
- 🎬 Entertainment
- 🏥 Health
- 🎓 Education
- 📄 Bills & Utilities
- ✈️ Travel
- ⛽ Gas
- 🛒 Groceries
- 📦 Other

## Screenshots

### Main Expense List
- View all expenses in a clean, organized list
- See expense totals at the top
- Quick actions to edit or delete expenses
- Filter by category using the filter button

### Add/Edit Expense
- Simple form to add or edit expenses
- Category dropdown with icons
- Date picker for expense date
- Optional description field

### Statistics
- Total expenses overview
- Category-wise breakdown with percentages
- Monthly expense tracking
- Visual progress indicators

## Technical Details

- **Framework**: Flutter 3.10+
- **Database**: SQLite (sqflite package)
- **State Management**: StatefulWidget with setState
- **Date Formatting**: intl package
- **Platform Support**: Android, iOS, Web, Windows, macOS, Linux

## Getting Started

1. Ensure Flutter is installed on your system
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Dependencies

- `flutter`: SDK
- `sqflite`: SQLite database
- `path`: File path utilities
- `intl`: Internationalization and date formatting
- `cupertino_icons`: iOS-style icons

## Project Structure

```
lib/
├── models/
│   └── expense.dart          # Expense data model
├── helpers/
│   └── database_helper.dart  # SQLite database operations
├── screens/
│   ├── expense_list_screen.dart     # Main expense list
│   ├── add_edit_expense_screen.dart # Add/edit expense form
│   └── statistics_screen.dart       # Statistics dashboard
├── utils/
│   └── theme.dart           # App theme and styling
└── main.dart               # App entry point
```

## Usage

### Adding an Expense
1. Tap the floating action button (+)
2. Fill in the expense details:
   - Title (required)
   - Amount (required)
   - Category (required)
   - Date (defaults to today)
   - Description (optional)
3. Tap "Save Expense"

### Editing an Expense
1. Tap on any expense in the list or tap the edit icon
2. Modify the desired fields
3. Tap "Update Expense"

### Deleting an Expense
1. Tap the delete icon on any expense
2. Confirm deletion in the popup dialog

### Viewing Statistics
1. Tap the statistics icon in the app bar or use the drawer menu
2. View total expenses, category breakdowns, and monthly trends

## License

This project is created for educational and personal use.
