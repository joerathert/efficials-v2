import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Base screen widget that provides consistent structure and theming
/// Eliminates repetitive screen setup code across all screens
abstract class BaseScreen extends StatefulWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;

  const BaseScreen({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.centerTitle = true,
  });

  /// Override this method to provide the main content of your screen
  Widget buildContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme);

  /// Override this method to handle back navigation if needed
  void onBackPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: widget.title != null ? _buildAppBar(colorScheme) : null,
      body: SafeArea(
        child: widget.buildContent(context, theme, colorScheme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      title: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Icon(
            Icons.sports,
            color: themeProvider.isDarkMode
                ? colorScheme.primary // Yellow in dark mode
                : Colors.black, // Black in light mode
            size: 32,
          );
        },
      ),
      centerTitle: widget.centerTitle,
      elevation: 0,
      leading: widget.showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => widget.onBackPressed(context),
            )
          : null,
      actions: widget.actions,
    );
  }
}

/// Convenience widget for screens with centered, constrained content
class CenteredScreen extends BaseScreen {
  final Widget child;
  final double maxWidth;

  const CenteredScreen({
    super.key,
    required this.child,
    this.maxWidth = 430,
    super.title,
    super.actions,
    super.showBackButton,
    super.centerTitle,
  });

  @override
  Widget buildContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
