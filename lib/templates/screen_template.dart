import 'package:flutter/material.dart';

/// 🎨 TEMPLATE FOR NEW SCREENS - Copy and customize this template
/// Follows Efficials Design System guidelines
/// See lib/design_system.md for full documentation

class ScreenTemplate extends StatelessWidget {
  const ScreenTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎯 REQUIRED: Always get theme colors at the start
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // 🎯 REQUIRED: Use theme background color
      backgroundColor: colorScheme.background,

      appBar: AppBar(
        // 🎯 REQUIRED: Use theme surface color
        backgroundColor: colorScheme.surface,
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Icon(
              // 🎯 REQUIRED: Theme-aware logo (black in light, yellow in dark)
              Icons.sports,
              color: themeProvider.isDarkMode
                  ? colorScheme.primary // Yellow in dark mode
                  : Colors.black, // Black in light mode
              size: 32,
            );
          },
        ),
        centerTitle: true,
        actions: [
          // 🎯 OPTIONAL: Theme toggle for key screens
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎯 REQUIRED: Use theme-aware text colors
              Text(
                'Screen Title',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  // ✅ CORRECT: Theme-aware color
                  color: colorScheme.onBackground,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Screen subtitle or description',
                style: TextStyle(
                  fontSize: 16,
                  // ✅ CORRECT: Theme-aware secondary text
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              // 🎯 EXAMPLE: Primary action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle primary action
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Primary Action',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🎯 EXAMPLE: Secondary action button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Handle secondary action
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Secondary Action',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 🎯 EXAMPLE: Content card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  // ✅ CORRECT: Theme-aware surface color
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      // ✅ CORRECT: Theme-aware shadow
                      color: colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card Title',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        // ✅ CORRECT: Theme-aware text
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Card content goes here. This automatically adapts to light and dark themes.',
                      style: TextStyle(
                        fontSize: 14,
                        // ✅ CORRECT: Theme-aware secondary text
                        color: colorScheme.onSurfaceVariant,
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

// 🎯 REMEMBER: Import these when using the template
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart'; // If using theme toggle
*/
