# Efficials Design System Guide

## 🎨 **Core Design Principles**

### **1. Color Usage Rules**
- ✅ **DO**: Use `Theme.of(context).colorScheme.primary` for brand yellow accents
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
    color: Theme.of(context).colorScheme.onBackground, // Primary text
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
                  color: colorScheme.onBackground, // Proper contrast
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
- [ ] All text uses `colorScheme.onBackground` or `colorScheme.onSurfaceVariant`
- [ ] Backgrounds use `colorScheme.background` or `colorScheme.surface`
- [ ] Buttons use theme-aware styling
- [ ] Shadows use `colorScheme.shadow.withOpacity(0.x)`

## 🎯 **Remember These Rules**

1. **Theme-aware logo** = Black in light mode, yellow in dark mode
2. **No yellow text** = Never use `Colors.yellow` for text content
3. **Theme colors only** = Use `Theme.of(context).colorScheme.*` for everything else
4. **Consistent buttons** = Use `ElevatedButton` for primary actions
5. **Proper contrast** = Let the theme system handle light/dark differences

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

This guide ensures you never have to point out the same issues again! 🎨
