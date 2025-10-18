import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverviewCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isCount;

  const OverviewCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withAlpha(25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isCount
                ? amount.toInt().toString()
                : NumberFormat.currency(
                    symbol: 'UGX ',
                    decimalDigits: 0,
                  ).format(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
