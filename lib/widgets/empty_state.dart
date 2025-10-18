import 'package:flutter/material.dart';

/// Generic empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? submessage;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.submessage,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurface.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface.withAlpha(179),
            ),
          ),
          if (submessage != null) ...[
            const SizedBox(height: 8),
            Text(
              submessage!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withAlpha(128),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onActionPressed != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.add),
              label: Text(actionLabel ?? 'Add Item'),
            ),
          ],
        ],
      ),
    );
  }
}
