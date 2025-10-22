import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../providers/api_provider.dart';
import 'modern_dialogs.dart';
import 'snackbar_helper.dart';

Future<void> showModernAddSaleDialog(
  BuildContext context,
  WidgetRef ref,
) async {
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
                        ModernTextField(
                          controller: priceController,
                          label: 'Total Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          suffix: 'UGX',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter total amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ModernTextField(
                          controller: quantityController,
                          label: 'Quantity',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
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
                        if (suppliersAsync.hasValue)
                          DropdownButtonFormField<int?>(
                            initialValue: selectedSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'Supplier (Optional)',
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No Supplier'),
                              ),
                              ...suppliersAsync.value!.map((supplier) {
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
                                    : suppliersAsync.value!
                                        .firstWhere((s) => s.id == value)
                                        .name;
                              });
                            },
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
                        SwitchListTile(
                          title: const Text('Commission Paid'),
                          value: isCommissionPaid,
                          onChanged: (value) {
                            setState(() => isCommissionPaid = value);
                          },
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
                      final commission = double.parse(
                        commissionController.text,
                      );

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
                      ref
                          .read(unpaidCommissionsNotifierProvider.notifier)
                          .refresh();

                      if (context.mounted) {
                        Navigator.pop(context);
                        SnackbarHelper.showSuccess(
                          context,
                          'Sale added successfully',
                        );
                      }
                    } catch (e) {
                      setState(() => isSaving = false);
                      if (context.mounted) {
                        SnackbarHelper.showError(context, e);
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
  BuildContext context,
  WidgetRef ref,
  Sale sale,
) async {
  final formKey = GlobalKey<FormState>();
  final productController = TextEditingController(text: sale.productName);
  final priceController = TextEditingController(text: sale.price.toString());
  final quantityController = TextEditingController(
    text: sale.quantity.toString(),
  );
  final commissionController = TextEditingController(
    text: sale.commission.toString(),
  );
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
                        ModernTextField(
                          controller: priceController,
                          label: 'Total Amount',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          suffix: 'UGX',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter total amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ModernTextField(
                          controller: quantityController,
                          label: 'Quantity',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
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
                        if (suppliersAsync.hasValue)
                          DropdownButtonFormField<int?>(
                            initialValue: selectedSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'Supplier (Optional)',
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No Supplier'),
                              ),
                              ...suppliersAsync.value!.map((supplier) {
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
                                    : suppliersAsync.value!
                                        .firstWhere((s) => s.id == value)
                                        .name;
                              });
                            },
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
                        SwitchListTile(
                          title: const Text('Commission Paid'),
                          value: isCommissionPaid,
                          onChanged: (value) {
                            setState(() => isCommissionPaid = value);
                          },
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
                      final commission = double.parse(
                        commissionController.text,
                      );

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
                      ref
                          .read(unpaidCommissionsNotifierProvider.notifier)
                          .refresh();

                      if (context.mounted) {
                        Navigator.pop(context);
                        SnackbarHelper.showSuccess(
                          context,
                          'Sale updated successfully',
                        );
                      }
                    } catch (e) {
                      setState(() => isSaving = false);
                      if (context.mounted) {
                        SnackbarHelper.showError(context, e);
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
