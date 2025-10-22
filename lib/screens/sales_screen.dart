import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../widgets/summary_card.dart';
import '../models/sale.dart';
import '../widgets/sale_dialogs.dart';
import '../widgets/generic_list_item.dart';
import '../widgets/generic_detail_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/common_screen_layout.dart';
import '../utils/error_handler.dart';
import 'package:intl/intl.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure data is loaded when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesNotifierProvider.notifier).loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final salesAsync = ref.watch(salesNotifierProvider);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return CommonScreenLayout(
      title: 'Sales',
      showBackButton: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: salesAsync.when(
        data: (sales) {
          final monthlySales = sales
              .where(
                (sale) =>
                    sale.saleDate.isAfter(
                      startOfMonth.subtract(const Duration(seconds: 1)),
                    ) &&
                    sale.saleDate.isBefore(
                      endOfMonth.add(const Duration(seconds: 1)),
                    ),
              )
              .toList()
            ..sort((a, b) => b.saleDate
                .compareTo(a.saleDate)); // Sort by date, most recent first

          final totalSales = monthlySales.fold<double>(
            0,
            (sum, sale) => sum + sale.totalAmount,
          );
          final totalCommission = monthlySales.fold<double>(
            0,
            (sum, sale) => sum + sale.commission,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surface
                      : colorScheme.primary,
                  child: Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Total Sales',
                          amount: totalSales,
                          icon: Icons.trending_up,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Total Commission',
                          amount: totalCommission,
                          icon: Icons.percent,
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: monthlySales.isEmpty
                      ? EmptyState(
                          icon: Icons.shopping_cart_outlined,
                          message: 'No sales yet',
                          submessage:
                              'Start adding sales to track your performance',
                          onActionPressed: _showAddDialog,
                          actionLabel: 'Add First Sale',
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref
                                .read(salesNotifierProvider.notifier)
                                .loadSales();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: monthlySales.length,
                            itemBuilder: (context, index) {
                              final sale = monthlySales[index];
                              return _buildSaleItem(sale, colorScheme);
                            },
                          ),
                        ),
                ),
              ],
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
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(salesNotifierProvider.notifier).loadSales();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleItem(Sale sale, ColorScheme colorScheme) {
    return GenericListItem(
      title: sale.productName,
      subtitle: DateFormat.yMMMd().format(sale.saleDate),
      secondarySubtitle:
          'Qty: ${sale.quantity} • Commission: ${NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0).format(sale.commission)}',
      trailing: NumberFormat.currency(
        symbol: 'UGX ',
        decimalDigits: 0,
      ).format(sale.totalAmount),
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

  Future<void> _showSaleDetails(Sale sale) async {
    final details = [
      DetailRow(label: 'Date', value: DateFormat.yMMMd().format(sale.saleDate)),
      DetailRow(label: 'Product Name', value: sale.productName),
      DetailRow(
        label: 'Amount',
        value: NumberFormat.currency(
          symbol: 'UGX ',
          decimalDigits: 0,
        ).format(sale.totalAmount),
      ),
      DetailRow(label: 'Quantity', value: sale.quantity.toString()),
      DetailRow(
        label: 'Commission',
        value: NumberFormat.currency(
          symbol: 'UGX ',
          decimalDigits: 0,
        ).format(sale.commission),
      ),
      DetailRow(
        label: 'Commission Status',
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
          _showEditDialog(sale);
        },
      ),
    );
  }

  Future<void> _showAddDialog() async {
    await showModernAddSaleDialog(context, ref);
  }

  Future<void> _showEditDialog(Sale sale) async {
    await showModernEditSaleDialog(context, ref, sale);
  }
}
