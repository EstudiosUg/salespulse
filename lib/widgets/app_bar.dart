import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        ),
      ),
      actions: actions?.map((action) {
        // Wrap actions to ensure they have the right color
        if (action is IconButton) {
          return IconButton(
            icon: action.icon,
            onPressed: action.onPressed,
            tooltip: action.tooltip,
            color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
          );
        }
        return action;
      }).toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
