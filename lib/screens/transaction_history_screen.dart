import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/api_provider.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../widgets/sale_dialogs.dart';
import '../widgets/expense_dialogs.dart';
import '../widgets/generic_list_item.dart';
import '../widgets/generic_detail_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart';
import '../widgets/common_screen_layout.dart';
import '../utils/error_handler.dart';

enum TransactionType { sales, expenses }

// Cache formatters for better performance
final _currencyFormatter = NumberFormat.currency(
  symbol: 'UGX ',
  decimalDigits: 0,
);
final _dateFormatter = DateFormat.yMMMd();

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final TransactionType initialType;

  const TransactionHistoryScreen({
    super.key,
    this.initialType = TransactionType.sales,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  late TransactionType _selectedType;
  DateTime? _selectedMonth;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CommonScreenLayout(
      title: 'Transaction History',
      showBackButton: true,
      body: Column(
        children: [
          _buildTypeSelectorWithFilter(colorScheme),
          _buildSearchBar(colorScheme),
          Expanded(
            child: _selectedType == TransactionType.sales
                ? _buildSalesHistory()
                : _buildExpensesHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectorWithFilter(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          // Type selector
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'Sales',
                      TransactionType.sales,
                      Icons.trending_up_rounded,
                      colorScheme,
                    ),
                  ),
                  Expanded(
                    child: _buildTypeButton(
                      'Expenses',
                      TransactionType.expenses,
                      Icons.trending_down_rounded,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Date filter button
          _buildDateFilterButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton(ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _selectMonth(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedMonth != null
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedMonth != null
                ? colorScheme.primary.withAlpha(76)
                : colorScheme.outline.withAlpha(25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: _selectedMonth != null
                  ? colorScheme.primary
                  : colorScheme.onSurface.withAlpha(179),
            ),
            if (_selectedMonth != null) ...[
              const SizedBox(width: 8),
              Text(
                DateFormat.MMM().format(_selectedMonth!),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedMonth = null;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    TransactionType type,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedType == type;
    final color =
        type == TransactionType.sales ? colorScheme.primary : colorScheme.error;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : colorScheme.onSurface.withAlpha(179),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? color : colorScheme.onSurface.withAlpha(179),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CustomSearchBar(
        hintText: _selectedType == TransactionType.sales
            ? 'Search product name...'
            : 'Search expense title...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        searchQuery: _searchQuery,
        onClear: () {
          setState(() {
            _searchQuery = '';
          });
        },
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    // Show custom month picker dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Month',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(child: _buildMonthGrid(context, now, colorScheme)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonth = null;
                      });
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                    child: const Text('Clear Filter'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    DateTime now,
    ColorScheme colorScheme,
  ) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = index + 1;
        final date = DateTime(now.year, month, 1);
        final isSelected = _selectedMonth != null &&
            _selectedMonth!.month == month &&
            _selectedMonth!.year == now.year;
        final isFuture = date.isAfter(now);

        return InkWell(
          onTap: isFuture
              ? null
              : () {
                  setState(() {
                    _selectedMonth = date;
                  });
                  Navigator.pop(context);
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : isFuture
                      ? colorScheme.surfaceContainerHighest.withAlpha(128)
                      : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                months[index].substring(0, 3),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isFuture
                      ? colorScheme.onSurface.withAlpha(102)
                      : isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesHistory() {
    final salesAsync = ref.watch(salesNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return salesAsync.when(
      data: (sales) {
        // Filter sales
        var filteredSales = sales.where((sale) {
          // Search filter
          final matchesSearch = _searchQuery.isEmpty ||
              sale.productName.toLowerCase().contains(_searchQuery);

          // Month filter
          final matchesMonth = _selectedMonth == null ||
              (sale.saleDate.year == _selectedMonth!.year &&
                  sale.saleDate.month == _selectedMonth!.month);

          return matchesSearch && matchesMonth;
        }).toList();

        // Sort by date descending
        filteredSales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

        if (filteredSales.isEmpty) {
          return _buildEmptyState(
            'No sales found',
            'Try adjusting your filters',
            colorScheme,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(salesNotifierProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: filteredSales.length,
            itemBuilder: (context, index) {
              final sale = filteredSales[index];
              return RepaintBoundary(child: _buildSaleItem(sale, colorScheme));
            },
            // Add cache extent for better scrolling
            cacheExtent: 500,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                ErrorHandler.getUserFriendlyMessage(error),
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesHistory() {
    final expensesAsync = ref.watch(expensesNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return expensesAsync.when(
      data: (expenses) {
        // Filter expenses
        var filteredExpenses = expenses.where((expense) {
          // Search filter
          final matchesSearch = _searchQuery.isEmpty ||
              expense.title.toLowerCase().contains(_searchQuery);

          // Month filter
          final matchesMonth = _selectedMonth == null ||
              (expense.expenseDate.year == _selectedMonth!.year &&
                  expense.expenseDate.month == _selectedMonth!.month);

          return matchesSearch && matchesMonth;
        }).toList();

        // Sort by date descending
        filteredExpenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

        if (filteredExpenses.isEmpty) {
          return _buildEmptyState(
            'No expenses found',
            'Try adjusting your filters',
            colorScheme,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(expensesNotifierProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: filteredExpenses.length,
            itemBuilder: (context, index) {
              final expense = filteredExpenses[index];
              return RepaintBoundary(
                child: _buildExpenseItem(expense, colorScheme),
              );
            },
            // Add cache extent for better scrolling
            cacheExtent: 500,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                ErrorHandler.getUserFriendlyMessage(error),
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleItem(Sale sale, ColorScheme colorScheme) {
    return GenericListItem(
      title: sale.productName,
      subtitle: _dateFormatter.format(sale.saleDate),
      secondarySubtitle:
          'Qty: ${sale.quantity} • Profit: ${_currencyFormatter.format(sale.commission)}',
      trailing: _currencyFormatter.format(sale.totalAmount),
      statusBadge: StatusBadge(
        label: sale.commissionPaid ? 'Paid' : 'Unpaid',
        color: sale.commissionPaid ? colorScheme.primary : colorScheme.error,
      ),
      leadingIcon: Icons.trending_up_rounded,
      leadingIconColor: colorScheme.primary,
      trailingColor: colorScheme.primary,
      onTap: () => _showSaleDetails(sale),
      onDismissed: () {
        ref.read(salesNotifierProvider.notifier).deleteSale(sale.id);
        ref.read(unpaidCommissionsNotifierProvider.notifier).refresh();
      },
      dismissConfirmTitle: 'Confirm Delete',
      dismissConfirmMessage: 'Are you sure you want to delete this sale?',
    );
  }

  Widget _buildExpenseItem(Expense expense, ColorScheme colorScheme) {
    return GenericListItem(
      title: expense.title,
      subtitle: _dateFormatter.format(expense.expenseDate),
      trailing: _currencyFormatter.format(expense.amount),
      leadingIcon: Icons.trending_down_rounded,
      leadingIconColor: colorScheme.error,
      trailingColor: colorScheme.error,
      onTap: () => _showExpenseDetails(expense),
      onDismissed: () {
        ref.read(expensesNotifierProvider.notifier).deleteExpense(expense.id);
        ref.read(unpaidCommissionsNotifierProvider.notifier).refresh();
      },
      dismissConfirmTitle: 'Confirm Delete',
      dismissConfirmMessage: 'Are you sure you want to delete this expense?',
    );
  }

  Future<void> _showSaleDetails(Sale sale) async {
    final details = [
      DetailRow(label: 'Date', value: _dateFormatter.format(sale.saleDate)),
      DetailRow(label: 'Product Name', value: sale.productName),
      DetailRow(
        label: 'Amount',
        value: _currencyFormatter.format(sale.totalAmount),
      ),
      DetailRow(label: 'Quantity', value: sale.quantity.toString()),
      DetailRow(
        label: 'Profit',
        value: _currencyFormatter.format(sale.commission),
      ),
      DetailRow(
        label: 'Profit Status',
        value: sale.commissionPaid ? 'Paid' : 'Unpaid',
      ),
      if (sale.supplierName?.isNotEmpty ?? false)
        DetailRow(label: 'Supplier', value: sale.supplierName!),
      if (sale.feedback?.isNotEmpty ?? false)
        DetailRow(label: 'Feedback', value: sale.feedback!),
    ];

    await showDialog(
      context: context,
      builder: (context) => GenericDetailDialog(
        title: 'Sale Details',
        details: details,
        onEdit: () {
          Navigator.pop(context);
          _showEditSaleDialog(sale);
        },
      ),
    );
  }

  Future<void> _showEditSaleDialog(Sale sale) async {
    await showModernEditSaleDialog(context, ref, sale);
  }

  Future<void> _showExpenseDetails(Expense expense) async {
    final details = [
      DetailRow(
        label: 'Date',
        value: _dateFormatter.format(expense.expenseDate),
      ),
      DetailRow(label: 'Title', value: expense.title),
      DetailRow(
        label: 'Amount',
        value: _currencyFormatter.format(expense.amount),
      ),
      if (expense.description?.isNotEmpty ?? false)
        DetailRow(label: 'Description', value: expense.description!),
    ];

    await showDialog(
      context: context,
      builder: (context) => GenericDetailDialog(
        title: 'Expense Details',
        details: details,
        onEdit: () {
          Navigator.pop(context);
          _showEditExpenseDialog(expense);
        },
      ),
    );
  }

  Future<void> _showEditExpenseDialog(Expense expense) async {
    await showModernEditExpenseDialog(context, ref, expense);
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    ColorScheme colorScheme,
  ) {
    return EmptyState(
      icon: _selectedType == TransactionType.sales
          ? Icons.shopping_bag_outlined
          : Icons.receipt_long_outlined,
      message: title,
      submessage: subtitle,
    );
  }
}
