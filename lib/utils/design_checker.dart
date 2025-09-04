/// 🎨 Design System Compliance Checker
/// Use this to verify your screens follow Efficials design guidelines

class DesignChecker {
  /// Common violations to check for
  static const List<String> _forbiddenPatterns = [
    r'Colors\.yellow', // Direct yellow usage
    r'Colors\.white', // Direct white usage
    r'Colors\.black', // Direct black usage (except logos)
    r'Colors\.grey\[', // Direct grey usage
    r'colorScheme\.primary.*Text', // Yellow text usage
  ];

  /// Allowed patterns for logos
  static const List<String> _logoPatterns = [
    r'Icons\.sports.*color: Colors\.black', // Black logo
  ];

  /// Check if a file contains design violations
  static List<String> checkFile(String filePath, String content) {
    final violations = <String>[];

    // Check for forbidden patterns
    for (final pattern in _forbiddenPatterns) {
      final regex = RegExp(pattern, multiLine: true);
      final matches = regex.allMatches(content);

      for (final match in matches) {
        final line = _getLineNumber(content, match.start);
        violations.add(
            '❌ Line $line: Forbidden pattern "$pattern" - Use theme colors instead');
      }
    }

    // Check for missing logo patterns in screens with app bars
    if (content.contains('AppBar') && !content.contains('Icons.sports')) {
      violations.add('⚠️  Missing sports logo in AppBar');
    }

    // Check for theme-aware logo usage (new requirement)
    if (content.contains('Icons.sports') &&
        content.contains('color: Colors.black')) {
      if (!content.contains('themeProvider.isDarkMode') &&
          !content.contains('brightness == Brightness.dark')) {
        violations.add(
            '⚠️  Logo should be theme-aware: black in light mode, yellow in dark mode');
      }
    }

    return violations;
  }

  /// Get line number from character position
  static int _getLineNumber(String content, int charPosition) {
    return content.substring(0, charPosition).split('\n').length;
  }

  /// Print design system summary
  static void printSummary() {
    print('''
🎨 Efficials Design System Summary
=====================================

✅ REQUIRED PATTERNS:
• Use Theme.of(context).colorScheme.* for all colors
• Black sports logo: Icons.sports, color: Colors.black
• Theme-aware text colors for proper contrast

❌ FORBIDDEN PATTERNS:
• Colors.yellow (causes contrast issues)
• Colors.white/Colors.black for UI elements
• Colors.grey[900] etc. (use theme colors)

📋 CHECKLIST:
• [ ] App bar has black sports logo
• [ ] No Colors.yellow used for text
• [ ] All backgrounds use colorScheme.background
• [ ] All text uses colorScheme.onBackground/onSurfaceVariant
• [ ] Buttons use ElevatedButton for primary actions

📁 FILES TO CHECK:
• lib/design_system.md - Full documentation
• lib/templates/screen_template.dart - Copy this for new screens
''');
  }
}

// 🎯 QUICK USAGE EXAMPLE:
/*
import 'utils/design_checker.dart';

// In your main() or test file:
final violations = DesignChecker.checkFile(
  'lib/screens/my_new_screen.dart',
  fileContentString
);

if (violations.isNotEmpty) {
  print('Design violations found:');
  violations.forEach(print);
} else {
  print('✅ Screen follows design system!');
}
*/
