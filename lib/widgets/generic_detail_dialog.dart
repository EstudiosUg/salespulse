import 'package:flutter/material.dart';

/// Generic detail row for dialogs
class DetailRow {
  final String label;
  final String value;

  const DetailRow({required this.label, required this.value});
}

/// Generic detail dialog
class GenericDetailDialog extends StatelessWidget {
  final String title;
  final List<DetailRow> details;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GenericDetailDialog({
    super.key,
    required this.title,
    required this.details,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: details
              .map((detail) => _buildDetailRow(detail.label, detail.value))
              .toList(),
        ),
      ),
      actions: [
        if (onDelete != null)
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (onEdit != null)
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
