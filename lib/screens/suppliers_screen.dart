import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../providers/api_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/generic_list_item.dart';
import '../widgets/common_screen_layout.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(suppliersNotifierProvider.notifier)
          .loadSuppliers(active: _showActiveOnly);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _toggleActiveFilter() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
    });
    ref
        .read(suppliersNotifierProvider.notifier)
        .loadSuppliers(active: _showActiveOnly);
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) => _SupplierFormDialog(
        onSave: (supplier) {
          ref.read(suppliersNotifierProvider.notifier).addSupplier(supplier);
        },
      ),
    );
  }

  void _showEditSupplierDialog(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => _SupplierFormDialog(
        supplier: supplier,
        onSave: (updatedSupplier) {
          ref.read(suppliersNotifierProvider.notifier).updateSupplier(
                supplier.id,
                updatedSupplier,
              );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Supplier supplier) {
    // The confirmation is now handled by GenericListItem's dismissible
    ref.read(suppliersNotifierProvider.notifier).deleteSupplier(supplier.id);
  }

  List<Supplier> _filterSuppliers(List<Supplier> suppliers) {
    return suppliers.where((supplier) {
      final matchesSearch = _searchQuery.isEmpty ||
          supplier.name.toLowerCase().contains(_searchQuery) ||
          (supplier.phone?.contains(_searchQuery) ?? false);

      final matchesActiveFilter = _showActiveOnly ? supplier.isActive : true;

      return matchesSearch && matchesActiveFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersState = ref.watch(suppliersNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CommonScreenLayout(
      title: 'Suppliers',
      showBackButton: true,
      actions: [
        IconButton(
          onPressed: _toggleActiveFilter,
          icon: Icon(
            _showActiveOnly ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.onSurface
                : colorScheme.onPrimary,
          ),
          tooltip: _showActiveOnly ? 'Show all suppliers' : 'Show active only',
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSupplierDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search suppliers...',
                  onChanged: _onSearchChanged,
                  searchQuery: _searchQuery,
                  onClear: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                const SizedBox(height: 12),
                // Active filter toggle
                Row(
                  children: [
                    FilterChip(
                      label: Text(
                          _showActiveOnly ? 'Active Only' : 'All Suppliers'),
                      selected: _showActiveOnly,
                      onSelected: (_) => _toggleActiveFilter(),
                      avatar: Icon(
                        _showActiveOnly
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Suppliers list
          Expanded(
            child: suppliersState.when(
              data: (suppliers) {
                final filteredSuppliers = _filterSuppliers(suppliers);

                if (filteredSuppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No suppliers found matching "$_searchQuery"'
                              : 'No suppliers found',
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(128),
                            fontSize: 14,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first supplier',
                            style: TextStyle(
                              color: colorScheme.onSurface.withAlpha(128),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSuppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = filteredSuppliers[index];
                    return GenericListItem(
                      title: supplier.name,
                      subtitle: supplier.phone ?? 'No phone',
                      secondarySubtitle: supplier.address,
                      trailing: '',
                      statusBadge: StatusBadge(
                        label: supplier.isActive ? 'Active' : 'Inactive',
                        color: supplier.isActive ? Colors.green : Colors.red,
                      ),
                      leadingIcon: Icons.business,
                      leadingIconColor: colorScheme.primary,
                      trailingColor: colorScheme.primary,
                      onTap: () => _showEditSupplierDialog(supplier),
                      onDismissed: () => _showDeleteConfirmation(supplier),
                      dismissConfirmTitle: 'Delete Supplier',
                      dismissConfirmMessage:
                          'Are you sure you want to delete "${supplier.name}"?',
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load suppliers',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(128),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(suppliersNotifierProvider.notifier)
                            .loadSuppliers(active: _showActiveOnly);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;
  final Function(Supplier) onSave;

  const _SupplierFormDialog({
    this.supplier,
    required this.onSave,
  });

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _phoneController.text = widget.supplier!.phone ?? '';
      _addressController.text = widget.supplier!.address ?? '';
      _isActive = widget.supplier!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final supplier = Supplier(
        id: widget.supplier?.id ?? 0,
        name: _nameController.text.trim(),
        email: null,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: null,
        isActive: _isActive,
      );

      widget.onSave(supplier);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle:
                      const Text('Active suppliers can be selected in sales'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.supplier == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
