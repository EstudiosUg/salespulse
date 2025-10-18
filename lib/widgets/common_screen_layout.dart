import 'package:flutter/material.dart';

/// A reusable screen layout that provides consistent styling across all screens
class CommonScreenLayout extends StatelessWidget {
  /// The title displayed in the AppBar
  final String title;

  /// The main content of the screen
  final Widget body;

  /// Whether to show the back button (default: true)
  final bool showBackButton;

  /// Optional actions to display in the AppBar
  final List<Widget>? actions;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Optional drawer
  final Widget? drawer;

  /// Whether to show the AppBar (default: true)
  final bool showAppBar;

  /// Custom AppBar if needed (overrides the default)
  final PreferredSizeWidget? customAppBar;

  /// Background color override (if null, uses theme surface color)
  final Color? backgroundColor;

  const CommonScreenLayout({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.showAppBar = true,
    this.customAppBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      drawer: drawer,
      appBar: customAppBar ??
          (showAppBar ? _buildAppBar(context, colorScheme, isDark) : null),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        ),
      ),
      actions: actions,
    );
  }
}

