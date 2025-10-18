import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthFilter extends StatelessWidget {
  final DateTime? selectedMonth;
  final Function(DateTime?) onMonthChanged;

  const MonthFilter({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withAlpha(50),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showMonthPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              selectedMonth != null
                  ? DateFormat.yMMM().format(selectedMonth!)
                  : 'All Time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
            ),
            itemCount: 13, // 12 months + "All Time"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildMonthTile(context, null, 'All Time');
              }
              
              final now = DateTime.now();
              final month = DateTime(now.year, index, 1);
              return _buildMonthTile(
                context,
                month,
                DateFormat.MMM().format(month),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthTile(BuildContext context, DateTime? month, String label) {
    final isSelected = (selectedMonth == null && month == null) ||
        (selectedMonth != null && month != null &&
         selectedMonth!.month == month.month &&
         selectedMonth!.year == month.year);
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: () {
          onMonthChanged(month);
          Navigator.pop(context);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline.withAlpha(50),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
