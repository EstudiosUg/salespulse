import 'package:flutter/material.dart';

/// Generic reusable list item card
class GenericListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? secondarySubtitle;
  final String trailing;
  final Widget? statusBadge;
  final IconData leadingIcon;
  final Color leadingIconColor;
  final Color trailingColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final String? dismissConfirmTitle;
  final String? dismissConfirmMessage;

  const GenericListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.secondarySubtitle,
    required this.trailing,
    this.statusBadge,
    required this.leadingIcon,
    required this.leadingIconColor,
    required this.trailingColor,
    this.onTap,
    this.onDismissed,
    this.dismissConfirmTitle,
    this.dismissConfirmMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final itemWidget = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: leadingIconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            leadingIcon,
            color: leadingIconColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(179),
                fontSize: 11,
              ),
            ),
            if (secondarySubtitle != null)
              Text(
                secondarySubtitle!,
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(179),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              trailing,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: trailingColor,
                fontSize: 13,
              ),
            ),
            if (statusBadge != null) statusBadge!,
          ],
        ),
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: Key(title + subtitle),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(dismissConfirmTitle ?? 'Confirm Delete'),
              content: Text(dismissConfirmMessage ??
                  'Are you sure you want to delete this item?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) => onDismissed!(),
        background: Container(
          color: colorScheme.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            Icons.delete,
            color: colorScheme.onError,
          ),
        ),
        child: itemWidget,
      );
    }

    return itemWidget;
  }
}

/// Status badge widget for list items
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}
