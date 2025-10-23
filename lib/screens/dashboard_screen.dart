import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/api_provider.dart';
import '../widgets/month_filter.dart';
import '../widgets/app_bar.dart';
import '../widgets/overview_card.dart';
import '../widgets/snackbar_helper.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import 'transaction_history_screen.dart';

// Cache formatters for better performance
final _currencyFormatter =
    NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? _selectedMonth = DateTime.now();

  // Helper method to safely convert API values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to safely convert API values to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    // Trigger initial data load for all providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesNotifierProvider.notifier).loadSales(forceRefresh: true);
      ref
          .read(expensesNotifierProvider.notifier)
          .loadExpenses(forceRefresh: true);
      // Ensure dashboard loads with the correct month
      ref.read(dashboardNotifierProvider.notifier).updateMonthYear(
            _selectedMonth?.month,
            _selectedMonth?.year,
          );
    });
  }

  void _refreshData() {
    // Refresh all data sources using notifier refresh methods
    ref.read(salesNotifierProvider.notifier).refresh();
    ref.read(expensesNotifierProvider.notifier).refresh();
    ref.read(dashboardNotifierProvider.notifier).refresh();
    ref.read(unpaidCommissionsNotifierProvider.notifier).refresh();
  }

  Future<void> _showMarkCommissionPaidDialog(
    String supplierName,
    int? supplierId,
    int salesCount,
    double totalCommission,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Profit Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Are you sure you want to mark all profits for $supplierName as paid?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sales:',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$salesCount product(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Profit:',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(totalCommission),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true && supplierId != null) {
      await _markSupplierCommissionsPaid(supplierId, supplierName);
    }
  }

  Future<void> _markSupplierCommissionsPaid(
    int supplierId,
    String supplierName,
  ) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      SnackbarHelper.showInfo(
        context,
        'Marking profits as paid for $supplierName...',
      );

      // Get unpaid sales for this supplier
      final apiService = ref.read(apiServiceProvider);
      final sales = await apiService.getSalesWithFilters(
        supplierId: supplierId,
        commissionPaid: false,
      );

      // Mark each sale's commission as paid
      for (final sale in sales) {
        await apiService.markCommissionPaid(sale.id);
      }

      // Refresh data
      _refreshData();

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        'Successfully marked ${sales.length} profit(s) as paid for $supplierName',
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final salesAsync = ref.watch(salesNotifierProvider);
    final expensesAsync = ref.watch(expensesNotifierProvider);

    // Enhanced dashboard data using StateNotifier providers
    final dashboardAsync = ref.watch(dashboardNotifierProvider);
    final unpaidCommissionsAsync = ref.watch(unpaidCommissionsNotifierProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Dashboard',
        showBackButton: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildSummaryCards(salesAsync, expensesAsync, dashboardAsync),
                const SizedBox(height: 32),
                _buildUnpaidCommissionsSection(unpaidCommissionsAsync),
                const SizedBox(height: 32),
                _buildHistorySection(salesAsync, expensesAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    AsyncValue<List<Sale>> salesAsync,
    AsyncValue<List<Expense>> expensesAsync,
    AsyncValue<Map<String, dynamic>> dashboardAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final startOfMonth = _selectedMonth != null
        ? DateTime(_selectedMonth!.year, _selectedMonth!.month, 1)
        : DateTime(2000);
    final endOfMonth = _selectedMonth != null
        ? DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0)
        : DateTime.now();

    // Calculate stats based on available data
    double totalSales = 0.0;
    double totalExpenses = 0.0;
    double totalCommission = 0.0;
    int totalProducts = 0;

    // Use dashboard data if available (preferred source)
    if (dashboardAsync.hasValue && dashboardAsync.value != null) {
      final dashboardData = dashboardAsync.value!;
      totalSales = _toDouble(dashboardData['total_sales']);
      totalExpenses = _toDouble(dashboardData['total_expenses']);
      totalCommission = _toDouble(dashboardData['commission_paid']);
      totalProducts = _toInt(dashboardData['total_products']);
    }
    // Fallback: calculate from sales and expenses data
    else if (salesAsync.hasValue && expensesAsync.hasValue) {
      final sales = salesAsync.value ?? [];
      final expenses = expensesAsync.value ?? [];

      for (var sale in sales) {
        if (sale.saleDate
                .isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            sale.saleDate
                .isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
          totalSales += sale.totalAmount;
          if (sale.commissionPaid) {
            totalCommission += sale.commission;
          }
          totalProducts += sale.quantity;
        }
      }

      for (var expense in expenses) {
        if (expense.expenseDate
                .isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            expense.expenseDate
                .isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
          totalExpenses += expense.amount;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    fontSize: 14,
                  ),
            ),
            MonthFilter(
              selectedMonth: _selectedMonth,
              onMonthChanged: (date) {
                setState(() {
                  _selectedMonth = date;
                });
                // Update dashboard data for the new month
                ref.read(dashboardNotifierProvider.notifier).updateMonthYear(
                      date?.month,
                      date?.year,
                    );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            OverviewCard(
              title: 'Total Sales',
              amount: totalSales,
              icon: Icons.trending_up_rounded,
              color: colorScheme.primary,
            ),
            OverviewCard(
              title: 'Total Expenses',
              amount: totalExpenses,
              icon: Icons.trending_down_rounded,
              color: colorScheme.error,
            ),
            OverviewCard(
              title: 'Paid Profit',
              amount: totalCommission,
              icon: Icons.account_balance_rounded,
              color: colorScheme.tertiary,
            ),
            OverviewCard(
              title: 'Total Products',
              amount: totalProducts.toDouble(),
              icon: Icons.inventory_2_rounded,
              color: colorScheme.secondary,
              isCount: true,
            ),
          ],
        ),
        // Unpaid commissions are now shown in a separate section below
      ],
    );
  }

  Widget _buildHistorySection(
    AsyncValue<List<Sale>> salesAsync,
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withAlpha(25),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildHistoryTile(
                'Sales History',
                salesAsync.when(
                  data: (sales) => sales.length,
                  loading: () => 0,
                  error: (_, __) => 0,
                ),
                colorScheme.primary,
                Icons.trending_up_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen(
                        initialType: TransactionType.sales,
                      ),
                    ),
                  );
                },
              ),
              Divider(
                color: colorScheme.outline.withAlpha(25),
                height: 1,
              ),
              _buildHistoryTile(
                'Expenses History',
                expensesAsync.when(
                  data: (expenses) => expenses.length,
                  loading: () => 0,
                  error: (_, __) => 0,
                ),
                colorScheme.error,
                Icons.trending_down_rounded,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen(
                        initialType: TransactionType.expenses,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTile(
    String title,
    int count,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count transactions',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(179),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withAlpha(179),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidCommissionsSection(
      AsyncValue<Map<String, dynamic>> unpaidCommissionsAsync) {
    final colorScheme = Theme.of(context).colorScheme;

    return unpaidCommissionsAsync.when(
      data: (unpaidData) {
        // Check if there are any unpaid commissions
        final hasUnpaid = unpaidData['has_unpaid'] ?? false;
        if (!hasUnpaid) return const SizedBox.shrink();

        final totalUnpaid = _toDouble(unpaidData['total_unpaid']);
        final List unpaidCommissions = unpaidData['unpaid_commissions'] ?? [];

        if (unpaidCommissions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unpaid Profits',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        fontSize: 14,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _currencyFormatter.format(totalUnpaid),
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withAlpha(25),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: unpaidCommissions.length,
                separatorBuilder: (context, index) => Divider(
                  color: colorScheme.outline.withAlpha(25),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final commission = unpaidCommissions[index];
                  final supplierName =
                      commission['supplier_name'] ?? 'Unknown Supplier';
                  final supplierId = commission['supplier_id'];
                  final totalCommission =
                      _toDouble(commission['total_commission']);
                  final salesCount = _toInt(commission['sales_count']);

                  return RepaintBoundary(
                    child: ListTile(
                      onTap: () => _showMarkCommissionPaidDialog(
                        supplierName,
                        supplierId,
                        salesCount,
                        totalCommission,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: colorScheme.error,
                        ),
                      ),
                      title: Text(
                        supplierName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '$salesCount unpaid product(s)',
                        style: TextStyle(
                          color: colorScheme.onSurface.withAlpha(179),
                          fontSize: 11,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currencyFormatter.format(totalCommission),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
