import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../providers/api_provider.dart';
import 'modern_dialogs.dart';
import 'snackbar_helper.dart';

Future<void> showModernAddSaleDialog(
    BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final productController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final commissionController = TextEditingController();
  final feedbackController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isCommissionPaid = false;
  int? selectedSupplierId;
  String? selectedSupplierName;
  bool isSaving = false;

  final suppliersAsync = ref.read(suppliersNotifierProvider);

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
                title: 'Add New Sale',
                subtitle: 'Record a new transaction',
                icon: Icons.add_shopping_cart,
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
                        // Product Information
                        SectionHeader(
                          title: 'Product Information',
                          icon: Icons.inventory_2_outlined,
                        ),
                        ModernTextField(
                          controller: productController,
                          label: 'Product Name',
                          icon: Icons.shopping_bag_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter product name';
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
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextField(
                                controller: priceController,
                                label: 'Price',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                suffix: 'UGX',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModernTextField(
                                controller: quantityController,
                                label: 'Quantity',
                                icon: Icons.numbers,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ModernTextField(
                          controller: commissionController,
                          label: 'Commission',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                          suffix: 'UGX',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter commission';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
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
                        suppliersAsync.when(
                          data: (suppliers) {
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Supplier (Optional)',
                                prefixIcon: Icon(Icons.business,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha(128),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withAlpha(77)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: selectedSupplierId,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('No Supplier'),
                                    ),
                                    ...suppliers.map((supplier) {
                                      return DropdownMenuItem<int?>(
                                        value: supplier.id,
                                        child: Text(supplier.name),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSupplierId = value;
                                      selectedSupplierName = value == null
                                          ? null
                                          : suppliers
                                              .firstWhere((s) => s.id == value)
                                              .name;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) =>
                              const Text('Error loading suppliers'),
                        ),
                        const SizedBox(height: 16),
                        ModernTextField(
                          controller: feedbackController,
                          label: 'Feedback (Optional)',
                          icon: Icons.comment_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        ModernDatePicker(
                          selectedDate: selectedDate,
                          onDateSelected: (date) {
                            setState(() => selectedDate = date);
                          },
                          label: 'Sale Date',
                        ),
                        const SizedBox(height: 16),
                        ModernSwitchTile(
                          title: 'Commission Paid',
                          subtitle: 'Mark if commission has been paid',
                          value: isCommissionPaid,
                          onChanged: (value) {
                            setState(() => isCommissionPaid = value);
                          },
                          icon: Icons.check_circle_outline,
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
                      final price = double.parse(priceController.text);
                      final quantity = int.parse(quantityController.text);
                      final commission =
                          double.parse(commissionController.text);

                      final sale = Sale(
                        id: '',
                        productName: productController.text,
                        price: price,
                        quantity: quantity,
                        commission: commission,
                        commissionPaid: isCommissionPaid,
                        supplierId: selectedSupplierId,
                        supplierName: selectedSupplierName,
                        feedback: feedbackController.text.isEmpty
                            ? null
                            : feedbackController.text,
                        saleDate: selectedDate,
                      );

                      await ref
                          .read(salesNotifierProvider.notifier)
                          .addSale(sale);
                      ref.invalidate(unpaidCommissionsProvider);

                      if (context.mounted) {
                        Navigator.pop(context);
                        SnackbarHelper.showSuccess(
                            context, 'Sale added successfully');
                      }
                    } catch (e) {
                      setState(() => isSaving = false);
                      if (context.mounted) {
                        SnackbarHelper.showError(context, 'Error: $e');
                      }
                    }
                  }
                },
                saveLabel: 'Add Sale',
                isSaving: isSaving,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showModernEditSaleDialog(
    BuildContext context, WidgetRef ref, Sale sale) async {
  final formKey = GlobalKey<FormState>();
  final productController = TextEditingController(text: sale.productName);
  final priceController = TextEditingController(text: sale.price.toString());
  final quantityController =
      TextEditingController(text: sale.quantity.toString());
  final commissionController =
      TextEditingController(text: sale.commission.toString());
  final feedbackController = TextEditingController(text: sale.feedback ?? '');
  DateTime selectedDate = sale.saleDate;
  bool isCommissionPaid = sale.commissionPaid;
  int? selectedSupplierId = sale.supplierId;
  String? selectedSupplierName = sale.supplierName;
  bool isSaving = false;

  final suppliersAsync = ref.read(suppliersNotifierProvider);

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
                title: 'Edit Sale',
                subtitle: 'Update transaction details',
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
                        // Product Information
                        SectionHeader(
                          title: 'Product Information',
                          icon: Icons.inventory_2_outlined,
                        ),
                        ModernTextField(
                          controller: productController,
                          label: 'Product Name',
                          icon: Icons.shopping_bag_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter product name';
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
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextField(
                                controller: priceController,
                                label: 'Price',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                suffix: 'UGX',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModernTextField(
                                controller: quantityController,
                                label: 'Quantity',
                                icon: Icons.numbers,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ModernTextField(
                          controller: commissionController,
                          label: 'Commission',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                          suffix: 'UGX',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter commission';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
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
                        suppliersAsync.when(
                          data: (suppliers) {
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Supplier (Optional)',
                                prefixIcon: Icon(Icons.business,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha(128),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withAlpha(77)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: selectedSupplierId,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('No Supplier'),
                                    ),
                                    ...suppliers.map((supplier) {
                                      return DropdownMenuItem<int?>(
                                        value: supplier.id,
                                        child: Text(supplier.name),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSupplierId = value;
                                      selectedSupplierName = value == null
                                          ? null
                                          : suppliers
                                              .firstWhere((s) => s.id == value)
                                              .name;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) =>
                              const Text('Error loading suppliers'),
                        ),
                        const SizedBox(height: 16),
                        ModernTextField(
                          controller: feedbackController,
                          label: 'Feedback (Optional)',
                          icon: Icons.comment_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        ModernDatePicker(
                          selectedDate: selectedDate,
                          onDateSelected: (date) {
                            setState(() => selectedDate = date);
                          },
                          label: 'Sale Date',
                        ),
                        const SizedBox(height: 16),
                        ModernSwitchTile(
                          title: 'Commission Paid',
                          subtitle: 'Mark if commission has been paid',
                          value: isCommissionPaid,
                          onChanged: (value) {
                            setState(() => isCommissionPaid = value);
                          },
                          icon: Icons.check_circle_outline,
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
                      final price = double.parse(priceController.text);
                      final quantity = int.parse(quantityController.text);
                      final commission =
                          double.parse(commissionController.text);

                      final updatedSale = Sale(
                        id: sale.id,
                        productName: productController.text,
                        price: price,
                        quantity: quantity,
                        commission: commission,
                        commissionPaid: isCommissionPaid,
                        supplierId: selectedSupplierId,
                        supplierName: selectedSupplierName,
                        feedback: feedbackController.text.isEmpty
                            ? null
                            : feedbackController.text,
                        saleDate: selectedDate,
                      );

                      await ref
                          .read(salesNotifierProvider.notifier)
                          .updateSale(sale.id, updatedSale);
                      ref.invalidate(unpaidCommissionsProvider);

                      if (context.mounted) {
                        Navigator.pop(context);
                        SnackbarHelper.showSuccess(
                            context, 'Sale updated successfully');
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
