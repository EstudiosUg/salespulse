import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/snackbar_helper.dart';
import '../widgets/common_screen_layout.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure data is loaded when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expensesNotifierProvider.notifier).loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final expensesAsync = ref.watch(expensesNotifierProvider);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return CommonScreenLayout(
      title: 'Expenses',
      showBackButton: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final monthlyExpenses = expenses
              .where((expense) =>
                  expense.expenseDate.isAfter(
                      startOfMonth.subtract(const Duration(seconds: 1))) &&
                  expense.expenseDate
                      .isBefore(endOfMonth.add(const Duration(seconds: 1))))
              .toList();

          final totalExpenses = monthlyExpenses.fold<double>(
              0, (sum, expense) => sum + expense.amount);

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surface
                      : colorScheme.primary,
                  child: SummaryCard(
                    title: 'Total Expenses',
                    amount: totalExpenses,
                    icon: Icons.trending_down,
                    color: colorScheme.error,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 300,
                  child: monthlyExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: colorScheme.onSurface.withAlpha(128),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withAlpha(179),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref
                                .read(expensesNotifierProvider.notifier)
                                .loadExpenses();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: monthlyExpenses.length,
                            itemBuilder: (context, index) {
                              final expense = monthlyExpenses[index];
                              return _buildExpenseItem(expense, colorScheme);
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading expenses: $error'),
              ElevatedButton(
                onPressed: () {
                  ref.read(expensesNotifierProvider.notifier).loadExpenses();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Delete'),
              content:
                  const Text('Are you sure you want to delete this expense?'),
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
        onDismissed: (direction) {
          ref.read(expensesNotifierProvider.notifier).deleteExpense(expense.id);
          // Invalidate dashboard providers to refresh dashboard data
          ref.invalidate(unpaidCommissionsProvider);
        },
        background: Container(
          color: colorScheme.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            Icons.delete,
            color: colorScheme.onError,
          ),
        ),
        child: ListTile(
          onTap: () => _showExpenseDetails(expense),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.error.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_down_rounded,
              color: colorScheme.error,
            ),
          ),
          title: Text(
            expense.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMd().format(expense.expenseDate),
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(179),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          trailing: Text(
            NumberFormat.currency(
              symbol: 'UGX ',
              decimalDigits: 0,
            ).format(expense.amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExpenseDetails(Expense expense) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  'Date', DateFormat.yMMMd().format(expense.expenseDate)),
              _buildDetailRow('Title', expense.title),
              _buildDetailRow(
                  'Amount',
                  NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                      .format(expense.amount)),
              if (expense.description?.isNotEmpty ?? false)
                _buildDetailRow('Description', expense.description!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(expense);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
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
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Expense'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (UGX)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    Navigator.pop(context);

                    final expense = Expense(
                      id: '', // Will be set by API
                      title: titleController.text,
                      amount: double.parse(amountController.text),
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                      expenseDate: selectedDate,
                    );

                    await ref
                        .read(expensesNotifierProvider.notifier)
                        .addExpense(expense);

                    // Invalidate dashboard providers to refresh dashboard data
                    ref.invalidate(unpaidCommissionsProvider);

                    if (context.mounted) {
                      SnackbarHelper.showSuccess(
                          context, 'Expense added successfully');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarHelper.showError(
                          context, 'Error adding expense: $e');
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Expense expense) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: expense.title);
    final amountController =
        TextEditingController(text: expense.amount.toString());
    final descriptionController =
        TextEditingController(text: expense.description ?? '');
    DateTime selectedDate = expense.expenseDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Expense'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (UGX)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    Navigator.pop(context);

                    final updatedExpense = Expense(
                      id: expense.id,
                      title: titleController.text,
                      amount: double.parse(amountController.text),
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                      expenseDate: selectedDate,
                    );

                    await ref
                        .read(expensesNotifierProvider.notifier)
                        .updateExpense(expense.id, updatedExpense);

                    // Invalidate dashboard providers to refresh dashboard data
                    ref.invalidate(unpaidCommissionsProvider);

                    if (context.mounted) {
                      SnackbarHelper.showSuccess(
                          context, 'Expense updated successfully');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackbarHelper.showError(
                          context, 'Error updating expense: $e');
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
