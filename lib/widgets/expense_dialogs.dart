import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/api_provider.dart';
import 'modern_dialogs.dart';
import 'snackbar_helper.dart';

Future<void> showModernAddExpenseDialog(
    BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              DialogHeader(
                title: 'Add New Expense',
                subtitle: 'Record a new expense',
                icon: Icons.receipt_long,
                onClose: () => Navigator.pop(context),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expense Information
                        SectionHeader(
                          title: 'Expense Information',
                          icon: Icons.description_outlined,
                        ),
                        ModernTextField(
                          controller: titleController,
                          label: 'Expense Title',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter expense title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Financial Details
                        SectionHeader(
                          title: 'Financial Details',
                          icon: Icons.attach_money,
                        ),
                        ModernTextField(
                          controller: amountController,
                          label: 'Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          suffix: 'UGX',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Additional Information
                        SectionHeader(
                          title: 'Additional Information',
                          icon: Icons.info_outline,
                        ),
                        ModernTextField(
                          controller: descriptionController,
                          label: 'Description (Optional)',
                          icon: Icons.comment_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        ModernDatePicker(
                          selectedDate: selectedDate,
                          onDateSelected: (date) {
                            setState(() => selectedDate = date);
                          },
                          label: 'Expense Date',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              DialogFooter(
                onCancel: () => Navigator.pop(context),
                onSave: () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isSaving = true);
                    try {
                      final amount = double.parse(amountController.text);

                      final expense = Expense(
                        id: '',
                        title: titleController.text,
                        amount: amount,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        expenseDate: selectedDate,
                      );

                      await ref
                          .read(expensesNotifierProvider.notifier)
                          .addExpense(expense);

                      if (context.mounted) {
                        Navigator.pop(context);
                        SnackbarHelper.showSuccess(
                            context, 'Expense added successfully');
                      }
                    } catch (e) {
                      setState(() => isSaving = false);
                      if (context.mounted) {
                        SnackbarHelper.showError(context, 'Error: $e');
                      }
                    }
                  }
                },
                saveLabel: 'Add Expense',
                isSaving: isSaving,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showModernEditExpenseDialog(
    BuildContext context, WidgetRef ref, Expense expense) async {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: expense.title);
  final amountController =
      TextEditingController(text: expense.amount.toString());
  final descriptionController =
      TextEditingController(text: expense.description ?? '');
  DateTime selectedDate = expense.expenseDate;
  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              DialogHeader(
                title: 'Edit Expense',
                subtitle: 'Update expense details',
                icon: Icons.edit,
                onClose: () => Navigator.pop(context),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expense Information
                        SectionHeader(
                          title: 'Expense Information',
                          icon: Icons.description_outlined,
                        ),
                        ModernTextField(
                          controller: titleController,
                          label: 'Expense Title',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter expense title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Financial Details
                        SectionHeader(
                          title: 'Financial Details',
                          icon: Icons.attach_money,
                        ),
                        ModernTextField(
                          controller: amountController,
                          label: 'Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          suffix: 'UGX',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Additional Information
                        SectionHeader(
                          title: 'Additional Information',
                          icon: Icons.info_outline,
                        ),
                        ModernTextField(
                          controller: descriptionController,
                          label: 'Description (Optional)',
                          icon: Icons.comment_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        ModernDatePicker(
                          selectedDate: selectedDate,
                          onDateSelected: (date) {
                            setState(() => selectedDate = date);
                          },
                          label: 'Expense Date',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              DialogFooter(
                onCancel: () => Navigator.pop(context),
                onSave: () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isSaving = true);
                    try {
                      final amount = double.parse(amountController.text);

                      final updatedExpense = Expense(
                        id: expense.id,
                        title: titleController.text,
                        amount: amount,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        expenseDate: selectedDate,
                      );

                      await ref
                          .read(expensesNotifierProvider.notifier)
                          .updateExpense(expense.id, updatedExpense);

                      if (context.mounted) {
                        Navigator.pop(context);
                        SnackbarHelper.showSuccess(
                            context, 'Expense updated successfully');
                      }
                    } catch (e) {
                      setState(() => isSaving = false);
                      if (context.mounted) {
                        SnackbarHelper.showError(context, 'Error: $e');
                      }
                    }
                  }
                },
                saveLabel: 'Update',
                isSaving: isSaving,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
