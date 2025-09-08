# Efficials Design System Guide

## 🎨 **Core Design Principles**

### **1. Color Usage Rules**
- ✅ **DO**: Use `Theme.of(context).colorScheme.primary` for brand yellow accents
- ✅ **DO**: Use `Theme.of(context).colorScheme.primary` for title text in dark mode
- ✅ **DO**: Use `Theme.of(context).colorScheme.onBackground` for text on backgrounds
- ❌ **NEVER**: Use `Colors.yellow` directly on text (causes contrast issues)
- ❌ **NEVER**: Use yellow text on white/light backgrounds

### **2. Logo/Icon Standards**
- ✅ **LIGHT MODE**: Use `Colors.black` for the main sports logo icon
- ✅ **DARK MODE**: Use `Theme.of(context).colorScheme.primary` (yellow) for the main sports logo icon
- ✅ **DO**: Use `Theme.of(context).colorScheme.primary` for accent icons
- ❌ **NEVER**: Use hardcoded colors for logos (except black in light mode)

### **3. Button Standards**
- ✅ **DO**: Use `ElevatedButton` for primary actions (filled with brand color)
- ✅ **DO**: Use theme colors for text and backgrounds
- ❌ **NEVER**: Mix outlined and filled buttons inconsistently

### **4. Text Color Hierarchy**
```dart
// ✅ CORRECT - Theme-aware colors
Text(
  'Title',
  style: TextStyle(
    color: Theme.of(context).colorScheme.brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primary // Yellow in dark mode
        : Theme.of(context).colorScheme.onBackground, // Dark in light mode
  ),
)

Text(
  'Subtitle',
  style: TextStyle(
    color: Theme.of(context).colorScheme.onSurfaceVariant, // Secondary text
  ),
)

// ❌ WRONG - Hardcoded colors
Text(
  'Title',
  style: TextStyle(
    color: Colors.yellow, // Bad contrast on light backgrounds
  ),
)
```

## 📱 **Component Patterns**

### **Card Selection Pattern**
```dart
// Selected card styling - Light Mode
decoration: BoxDecoration(
  color: Colors.grey.shade100, // Light gray background when selected
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: Colors.black, // Black border when selected
    width: 2,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.2), // Soft black shadow
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ],
),

// Selected card styling - Dark Mode (Original)
decoration: BoxDecoration(
  color: colorScheme.primary.withOpacity(0.1), // Yellow background when selected
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: colorScheme.primary, // Yellow border when selected
    width: 2,
  ),
  boxShadow: [
    BoxShadow(
      color: colorScheme.shadow.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ],
),

// Selected card content - Light Mode
Text(
  title,
  style: TextStyle(
    color: colorScheme.onSurface, // Black text when selected
    fontWeight: FontWeight.bold,
  ),
),

Icon(
  icon,
  color: colorScheme.onSurface, // Black icon when selected
),

Icon(
  Icons.check_circle,
  color: Colors.black, // Black checkmark in light mode
),

// Selected card content - Dark Mode (Original)
Text(
  title,
  style: TextStyle(
    color: colorScheme.primary, // Yellow text when selected
    fontWeight: FontWeight.bold,
  ),
),

Icon(
  icon,
  color: colorScheme.primary, // Yellow icon when selected
),

Icon(
  Icons.check_circle,
  color: colorScheme.primary, // Yellow checkmark in dark mode
),
```

### **App Bar Pattern**
```dart
AppBar(
  backgroundColor: Theme.of(context).colorScheme.surface,
  title: Icon(
    Icons.sports,
    color: Theme.of(context).colorScheme.brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primary // Yellow in dark mode
        : Colors.black, // Black in light mode
    size: 32,
  ),
  actions: [
    IconButton(
      icon: Icon(
        Icons.logout,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () => _handleLogout(),
    ),
  ],
)
```

**Alternative using Provider (Recommended):**
```dart
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Icon(
        Icons.sports,
        color: themeProvider.isDarkMode
            ? Theme.of(context).colorScheme.primary // Yellow in dark mode
            : Colors.black, // Black in light mode
        size: 32,
      ),
      // ... rest of app bar
    );
  },
)
```

### **Card/Container Pattern**
```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceVariant,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
        blurRadius: 8,
      ),
    ],
  ),
  child: Text(
    'Content',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
)
```

## 🚀 **Quick Start Template for New Screens**

Use this template for all new screens:

```dart
class NewScreen extends StatelessWidget {
  const NewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Icon(
          Icons.sports,
          color: theme.brightness == Brightness.dark
              ? colorScheme.primary // Yellow in dark mode
              : Colors.black, // Black in light mode
          size: 32,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Screen Title',
                style: TextStyle(
                  color: theme.brightness == Brightness.dark
                      ? colorScheme.primary // Yellow in dark mode
                      : colorScheme.onBackground, // Dark in light mode
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ... rest of content
            ],
          ),
        ),
      ),
    );
  }
}
```

## ⚡ **Automatic Theme Support**

### **How It Works**
When you use theme colors instead of hardcoded colors:

```dart
// ✅ Theme-aware - automatically switches between light/dark
Text('Hello', style: TextStyle(color: colorScheme.onBackground))

// ❌ Hardcoded - doesn't adapt to theme changes
Text('Hello', style: TextStyle(color: Colors.white))
```

### **Benefits**
- ✅ **Automatic light/dark switching** without code changes
- ✅ **Consistent colors** across the entire app
- ✅ **Accessibility compliance** with proper contrast ratios
- ✅ **Easy maintenance** - change theme colors in one place

## 🔧 **IDE Setup Recommendations**

### **VS Code Snippets**
Create these snippets for quick theme-aware code:

```json
{
  "Theme Colors": {
    "prefix": "theme-colors",
    "body": [
      "final theme = Theme.of(context);",
      "final colorScheme = theme.colorScheme;",
      "",
      "// Colors:",
      "// colorScheme.background - Main background",
      "// colorScheme.surface - Card/surface backgrounds",
      "// colorScheme.onBackground - Primary text",
      "// colorScheme.onSurfaceVariant - Secondary text",
      "// colorScheme.primary - Brand color (yellow)"
    ]
  }
}
```

## 📋 **Checklist for New Screens**

Before creating a new screen, verify:

- [ ] App bar uses theme-aware logo (black in light mode, yellow in dark mode)
- [ ] No `Colors.yellow` used directly for text
- [ ] Title text uses theme-aware colors (yellow in dark mode, dark in light mode)
- [ ] Other text uses `colorScheme.onBackground` or `colorScheme.onSurfaceVariant`
- [ ] Backgrounds use `colorScheme.background` or `colorScheme.surface`
- [ ] Buttons use theme-aware styling
- [ ] Shadows use `colorScheme.shadow.withOpacity(0.x)`

## 🎯 **Remember These Rules**

1. **Theme-aware logo** = Black in light mode, yellow in dark mode
2. **Theme-aware titles** = Yellow in dark mode, dark in light mode
3. **No yellow text** = Never use `Colors.yellow` for text content (except via theme)
4. **Theme colors only** = Use `Theme.of(context).colorScheme.*` for everything else
5. **Consistent buttons** = Use `ElevatedButton` for primary actions
6. **Proper contrast** = Let the theme system handle light/dark differences

## 🔄 **Updating Existing Screens**

When updating existing screens to follow the new logo guidelines:

### **Current Logo Implementation:**
```dart
// ❌ OLD - Static black logo
title: const Icon(
  Icons.sports,
  color: Colors.black,
  size: 32,
),
```

### **Updated Logo Implementation:**
```dart
// ✅ NEW - Theme-aware logo
title: Icon(
  Icons.sports,
  color: Theme.of(context).colorScheme.brightness == Brightness.dark
      ? Theme.of(context).colorScheme.primary // Yellow in dark mode
      : Colors.black, // Black in light mode
  size: 32,
),
```

### **Using Provider (Recommended):**
```dart
title: Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return Icon(
      Icons.sports,
      color: themeProvider.isDarkMode
          ? Theme.of(context).colorScheme.primary // Yellow in dark mode
          : Colors.black, // Black in light mode
      size: 32,
    );
  },
),
```

## 🔧 **Common Implementation Patterns**

### **Navigation & Data Flow Patterns**

#### **1. Step Screen Navigation (Multi-step Forms)**
```dart
// ✅ CORRECT - Data preservation with navigation
Navigator.pushNamed(
  context,
  '/next-step',
  arguments: {
    ...previousData,
    'newField': newValue,
  },
);

// ❌ AVOID - Losing data between steps
Navigator.pushNamed(context, '/next-step');
```

#### **2. Data Persistence in didChangeDependencies()**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

  if (args != null) {
    setState(() {
      // Initialize data from previous screen
      selectedData = args['selectedData'] ?? {};
    });
  }
}
```

#### **3. Null-Safe Argument Handling**
```dart
// ✅ CORRECT - Safe argument access
final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
final data = args?['key'] ?? defaultValue;

// ❌ AVOID - Potential null pointer exceptions
final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
final data = args['key'];
```

### **Dialog & Modal Patterns**

#### **1. Constrained Dialog Width**
```dart
// ✅ CORRECT - Prevents full-width dialogs on web
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400), // Max width constraint
      child: SizedBox(
        width: double.maxFinite, // Still responsive on mobile
        child: ListView.builder(...),
      ),
    ),
  ),
);
```

#### **2. Theme-Aware Dialog Styling**
```dart
AlertDialog(
  backgroundColor: Theme.of(context).colorScheme.surface,
  title: Text(
    'Title',
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
  ),
  // ...
)
```

### **Form & Data Patterns**

#### **1. Consistent Data Keys**
```dart
// ✅ CORRECT - Use consistent keys across screens
const String COMPETITION_LEVELS_KEY = 'competitionLevels';

// In form fields:
competitionLevels: _selectedLevels,

// ❌ AVOID - Mixed key names
// Some screens use 'levels', others use 'competitionLevels'
```

#### **2. Dropdown Form Field Pattern**
```dart
DropdownButtonFormField<String>(
  decoration: InputDecoration(
    labelText: 'Select Option',
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  items: options.map((option) => DropdownMenuItem(
    value: option,
    child: Text(option),
  )).toList(),
  onChanged: (value) => setState(() => _selectedValue = value),
),
```

### **Layout & Responsive Patterns**

#### **1. Centered Content with Max Width**
```dart
// ✅ RECOMMENDED - Centered, responsive layout with optimal width
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 430), // Optimal balance for readability
    child: Padding(
      padding: const EdgeInsets.all(20.0), // Standard padding for mobile
      child: Column(...),
    ),
  ),
)

// Alternative - Wider for data-heavy screens
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600), // Use for screens with lots of data
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(...),
    ),
  ),
)
```

#### **2. Button Width Consistency**
```dart
// ✅ RECOMMENDED - Full-width for mobile-first UX
ElevatedButton(
  onPressed: _handleContinue,
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 56), // Full width, touch-friendly height
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: const Text('Continue'),
)

// Alternative - Fixed width for specific use cases
SizedBox(
  width: 300, // Use only when full-width isn't appropriate
  child: ElevatedButton(
    onPressed: _handleContinue,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: const Text('Continue'),
  ),
)
```

#### **3. Column Spacing Optimization**
```dart
// ✅ RECOMMENDED - Optimized spacing for label-value pairs
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SizedBox(
      width: 160, // Wide enough for longest labels (e.g., "Competition Level")
      child: Text(
        '${e.key}:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
    ),
    const SizedBox(width: 16), // Optimal gap for visual separation
    Expanded(
      child: Text(
        e.value,
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
    ),
  ],
)

// 📏 Spacing Guidelines:
// - Label width: 120-160px (based on longest expected label)
// - Gap: 12-16px (balances separation without excessive whitespace)
// - Text size: 16px for optimal readability
// - Font weight: w500 for labels, regular for values
```

#### **4. Chronological List Sorting**
```dart
// ✅ RECOMMENDED - Sort lists by date and time (nearest first)
games.sort((a, b) {
  final dateA = a['date'] as DateTime?;
  final dateB = b['date'] as DateTime?;
  final timeA = a['time'] as TimeOfDay?;
  final timeB = b['time'] as TimeOfDay?;

  // Handle null dates - put items without dates at the end
  if (dateA == null && dateB == null) return 0;
  if (dateA == null) return 1;
  if (dateB == null) return -1;

  // Compare dates first
  final dateComparison = dateA.compareTo(dateB);
  if (dateComparison != 0) return dateComparison;

  // If dates are the same, compare times
  if (timeA == null && timeB == null) return 0;
  if (timeA == null) return 1;
  if (timeB == null) return -1;

  // Convert times to minutes for comparison
  final timeAInMinutes = timeA.hour * 60 + timeA.minute;
  final timeBInMinutes = timeB.hour * 60 + timeB.minute;
  return timeAInMinutes.compareTo(timeBInMinutes);
});

// 📏 Sorting Guidelines:
// - Primary sort: Date (earliest first)
// - Secondary sort: Time (earliest first for same-day items)
// - Null handling: Items without dates/times go to end
// - User-centric: Most urgent items appear first
// - Real-time: Apply after each data fetch
```

#### **5. Floating Action Button Positioning (Cross-Platform)**
```dart
// ✅ RECOMMENDED - Consistent FAB overlay across web and mobile
floatingActionButton: Stack(
  children: [
    Positioned(
      bottom: 40, // Optimal distance from bottom for accessibility
      right: (MediaQuery.of(context).size.width -
              (MediaQuery.of(context).size.width > 550 ? 550 : MediaQuery.of(context).size.width)) /
          2 +
          20, // Position relative to constrained content area (550px)
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FAB content with expand/collapse functionality
        ],
      ),
    ),
  ],
)

// 📏 Positioning Guidelines:
// - Bottom: 40-60px (optimal for thumb accessibility)
// - Right offset: 20px from constrained content edge
// - Content width reference: 550px (matches main content constraint)
// - Platform agnostic: Same formula works on web and mobile
// - Responsive: Automatically adjusts to screen size
```

## 🔧 **Reusable Components Library**

The codebase now includes several reusable components to reduce duplication and ensure consistency:

### **1. BaseScreen & CenteredScreen**
```dart
import '../widgets/base_screen.dart';

// Most screens should extend BaseScreen
class MyScreen extends BaseScreen {
  @override
  Widget buildContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return CenteredScreen(
      child: Column(children: [/* content */]),
    ).buildContent(context, theme, colorScheme);
  }
}
```

### **2. Form Components**
```dart
import '../widgets/form_section.dart';

// Consistent form styling
FormSection(
  title: 'Personal Information',
  children: [
    StyledTextField(
      labelText: 'First Name',
      controller: _firstNameController,
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    ),
    StyledDropdown(
      labelText: 'State',
      items: _stateItems,
      value: _selectedState,
      onChanged: (value) => setState(() => _selectedState = value),
    ),
  ],
)
```

### **3. Standardized Buttons**
```dart
import '../widgets/standard_button.dart';

// Consistent button styling across all screens
StandardButton(
  text: 'Continue',
  onPressed: _handleContinue,
  isLoading: _isLoading,
  width: 400,
  height: 50,
)

// For secondary actions
StandardOutlinedButton(
  text: 'Cancel',
  onPressed: _handleCancel,
  width: 400,
  height: 50,
)
```

### **4. Firebase Constants**
```dart
import '../constants/firebase_constants.dart';

// Type-safe collection and field references
_firestore.collection(FirebaseCollections.users)
  .doc(userId)
  .update({
    FirebaseFields.email: newEmail,
    FirebaseFields.status: FirebaseValues.statusPublished,
  });
```

### **Error Handling Patterns**

#### **1. Form Validation with SnackBar**
```dart
if (_selectedValue == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please select a value'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
```

#### **2. Async Operation Error Handling**
```dart
try {
  await _performOperation();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Success!')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## 📋 **Updated Checklist for New Screens**

Before creating a new screen, verify:

- [ ] App bar uses theme-aware logo (black in light mode, yellow in dark mode)
- [ ] No `Colors.yellow` used directly for text
- [ ] Title text uses theme-aware colors (yellow in dark mode, dark in light mode)
- [ ] Other text uses `colorScheme.onBackground` or `colorScheme.onSurfaceVariant`
- [ ] Backgrounds use `colorScheme.background` or `colorScheme.surface`
- [ ] Buttons use theme-aware styling with standardized height (50px)
- [ ] Shadows use `colorScheme.shadow.withOpacity(0.x)`
- [ ] Dialogs use `ConstrainedBox(maxWidth: 400)` for proper width
- [ ] Navigation preserves data between screens
- [ ] Form validation includes user-friendly error messages
- [ ] Null-safe argument handling in `didChangeDependencies()`
- [ ] Responsive layout with `Center` + `ConstrainedBox(maxWidth: 430)` for optimal readability
- [ ] Column spacing follows 160px labels + 16px gap pattern for label-value pairs
- [ ] Floating Action Buttons use cross-platform positioning pattern (if applicable)
- [ ] Lists with dates/times use chronological sorting (nearest first)

## 🎯 **Key Patterns to Remember**

1. **Theme-aware logo** = Black in light mode, yellow in dark mode
2. **Theme-aware titles** = Yellow in dark mode, dark in light mode
3. **No yellow text** = Never use `Colors.yellow` for text content (except via theme)
4. **Theme colors only** = Use `Theme.of(context).colorScheme.*` for everything else
5. **Standardized buttons** = All buttons use 50px height with `SizedBox(width: 400, height: 50, child: ElevatedButton(...))`
6. **Constrained dialogs** = Always use `ConstrainedBox(maxWidth: 400)` for dialogs
7. **Data preservation** = Pass complete data objects between navigation steps
8. **Null safety** = Use `?.` operators and null-aware spreads (`...?args`)
9. **Responsive layout** = `Center` + `ConstrainedBox(maxWidth: 430)` for optimal readability, use 600 for data-heavy screens
10. **Cross-platform FAB** = Position FAB relative to constrained content area for consistent overlay
11. **Chronological sorting** = Sort lists by date/time with nearest items first
12. **Proper contrast** = Let the theme system handle light/dark differences

This guide ensures you never have to point out the same issues again! 🎨
