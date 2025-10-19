import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/api_provider.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import '../widgets/common_screen_layout.dart';
import '../widgets/snackbar_helper.dart';
import '../services/file_download_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final profileAsync = ref.watch(profileNotifierProvider);

    return CommonScreenLayout(
      title: 'Settings',
      showBackButton: false,
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          profileAsync.when(
            data: (profile) => profile != null
                ? ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile.avatar != null
                          ? NetworkImage(
                              ApiConfig.getAvatarUrl(profile.avatar!))
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: profile.avatar == null
                          ? Text(
                              profile.firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(profile.fullName),
                    subtitle: Text(profile.email),
                    trailing: profile.isPremium
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  )
                : const SizedBox.shrink(),
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading profile...'),
            ),
            error: (error, stack) => ListTile(
              leading: const Icon(Icons.error),
              title: Text('Error: $error'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account Settings'),
            subtitle: const Text('Manage your account'),
            onTap: () => _showAccountSettingsDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _handleLogout(),
          ),
          const Divider(),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const Divider(),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Data'),
            subtitle: const Text('Export your transactions'),
            onTap: () => _showExportDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Data'),
            subtitle: const Text('Reload sales and expenses'),
            onTap: () => _refreshData(),
          ),
          const Divider(),

          // Security Section
          _buildSectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Update your password'),
            onTap: () => _showChangePasswordDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Permanently delete your account'),
            onTap: () => _showDeleteAccountDialog(),
          ),
          const Divider(),

          // App Info Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _showAccountSettingsDialog() async {
    final profileAsync = ref.read(profileNotifierProvider);

    if (!profileAsync.hasValue || profileAsync.value == null) {
      SnackbarHelper.showError(context, 'Profile data not available');
      return;
    }

    final profile = profileAsync.value!;
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);
    final emailController = TextEditingController(text: profile.email);
    final phoneController = TextEditingController(text: profile.phoneNumber);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Settings'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickAndUploadAvatar(),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: profile.avatar != null
                        ? NetworkImage(
                            'http://192.168.110.151:8000/storage/${profile.avatar}')
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: profile.avatar == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to change avatar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
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
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updatedUser = User(
                  id: profile.id,
                  name: profile.name,
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  email: emailController.text,
                  phoneNumber: phoneController.text,
                  avatar: profile.avatar,
                  twoFactorEnabled: profile.twoFactorEnabled,
                  isPremium: profile.isPremium,
                  premiumExpiresAt: profile.premiumExpiresAt,
                  theme: profile.theme,
                  isActive: profile.isActive,
                );

                try {
                  await ref
                      .read(profileNotifierProvider.notifier)
                      .updateProfile(updatedUser);
                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackbarHelper.showSuccess(
                        context, 'Profile updated successfully');
                  }
                } catch (error) {
                  if (context.mounted) {
                    SnackbarHelper.showError(
                        context, 'Error updating profile: $error');
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
      requestFullMetadata:
          false, // Use Android Photo Picker (no permissions needed on Android 13+)
    );

    if (image != null) {
      try {
        await ref
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(File(image.path));
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Avatar updated successfully');
        }
      } catch (error) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Error uploading avatar: $error');
        }
      }
    }
  }

  Future<void> _showExportDialog() async {
    final profileAsync = ref.read(profileNotifierProvider);
    final isPremium =
        profileAsync.hasValue && profileAsync.value?.isPremium == true;

    if (!isPremium) {
      SnackbarHelper.showInfo(
        context,
        'Data export is a premium feature. Upgrade to premium to export your data.',
      );
      return;
    }

    DateTime? startDate;
    DateTime? endDate;
    bool includeSales = true;
    bool includeExpenses = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final colorScheme = Theme.of(context).colorScheme;

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.file_download, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Export Data'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Start Date Card
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ??
                            DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => startDate = date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: startDate != null
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: startDate != null
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_outlined,
                              color: startDate != null
                                  ? colorScheme.primary
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  startDate != null
                                      ? '${startDate!.day} ${_getMonthName(startDate!.month)} ${startDate!.year}'
                                      : 'Tap to select',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: startDate != null
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // End Date Card
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => endDate = date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: endDate != null
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: endDate != null
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_outlined,
                              color: endDate != null
                                  ? colorScheme.primary
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  endDate != null
                                      ? '${endDate!.day} ${_getMonthName(endDate!.month)} ${endDate!.year}'
                                      : 'Tap to select',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: endDate != null
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Data to Include',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Sales Transactions'),
                    subtitle: const Text('Include all sales data'),
                    value: includeSales,
                    onChanged: (value) =>
                        setState(() => includeSales = value ?? true),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Expense Transactions'),
                    subtitle: const Text('Include all expense data'),
                    value: includeExpenses,
                    onChanged: (value) =>
                        setState(() => includeExpenses = value ?? true),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (startDate != null && endDate != null) {
                    Navigator.pop(context);
                    _exportData(
                        startDate!, endDate!, includeSales, includeExpenses);
                  } else {
                    SnackbarHelper.showError(
                        context, 'Please select both start and end dates');
                  }
                },
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Export'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportData(DateTime startDate, DateTime endDate,
      bool includeSales, bool includeExpenses) async {
    // No storage permission needed - using app-specific directories

    try {
      // Show loading indicator
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Starting export...');
      }

      // Get user info for export
      final profileAsync = ref.read(profileNotifierProvider);
      final userName = profileAsync.hasValue && profileAsync.value != null
          ? profileAsync.value!.fullName
          : '';

      final exportParams = {
        'startDate':
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'endDate':
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        'includeSales': includeSales,
        'includeExpenses': includeExpenses,
        'userName': userName,
      };

      final exportResult =
          await ref.read(exportDataProvider(exportParams).future);

      if (!mounted) return;

      // Extract download URL and email status
      final downloadUrl = exportResult['download_url'] as String?;
      final emailSent = exportResult['email_sent'] as bool? ?? false;

      // Generate filename with user name
      final userNameForFile = userName.replaceAll(' ', '_');
      final fileName = exportResult['file_name'] as String? ??
          '${userNameForFile}_export_${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}.xlsx';

      if (emailSent) {
        // Get user email for notification
        final userEmail = profileAsync.hasValue && profileAsync.value != null
            ? profileAsync.value!.email
            : '';

        // Show notification that opens email app when tapped
        await NotificationService.showEmailExportNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: 'Export Sent via Email',
          body:
              'Your data export has been sent to your email. Tap to open your email app.',
          userEmail: userEmail,
        );

        if (!mounted) return;
        SnackbarHelper.showSuccess(
          context,
          'Export sent to your email successfully!',
        );
      }

      // If download URL is available, download the file
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        final authState = ref.read(authNotifierProvider);
        final token = authState.token;

        // Download file in background
        FileDownloadService.downloadFile(
          url: downloadUrl,
          filename: fileName,
          authToken: token,
        ).then((filePath) {
          if (filePath != null && mounted) {
            SnackbarHelper.showSuccess(
              context,
              'Export downloaded! Tap notification to open.',
            );
          }
        });

        if (!mounted) return;
        SnackbarHelper.showSuccess(
          context,
          'Downloading export file...',
        );
      } else if (!emailSent) {
        // No download URL and no email sent
        if (!mounted) return;
        SnackbarHelper.showError(
          context,
          'Export completed but download link not available',
        );
      }
    } catch (error) {
      // Show error notification
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Export Failed',
        body: 'Failed to export data: $error',
      );

      if (!mounted) return;
      SnackbarHelper.showError(context, 'Error exporting data: $error');
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear all cached data before logout
      ref.invalidate(salesNotifierProvider);
      ref.invalidate(expensesNotifierProvider);
      ref.invalidate(suppliersNotifierProvider);
      ref.invalidate(profileNotifierProvider);
      ref.invalidate(settingsNotifierProvider);

      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      // Refresh sales and expenses data
      await ref.read(salesNotifierProvider.notifier).loadSales();
      await ref.read(expensesNotifierProvider.notifier).loadExpenses();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Data refreshed successfully');
      }
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error refreshing data: $error');
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref.read(apiServiceProvider).changePassword(
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                        newPasswordConfirmation: confirmPasswordController.text,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackbarHelper.showSuccess(
                        context, 'Password changed successfully');
                  }
                } catch (error) {
                  if (context.mounted) {
                    SnackbarHelper.showError(
                        context, 'Error changing password: $error');
                  }
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Enter Password to Confirm',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref
            .read(apiServiceProvider)
            .deleteAccount(passwordController.text);

        // Clear all cached data before logout
        ref.invalidate(salesNotifierProvider);
        ref.invalidate(expensesNotifierProvider);
        ref.invalidate(suppliersNotifierProvider);
        ref.invalidate(profileNotifierProvider);
        ref.invalidate(settingsNotifierProvider);

        // Logout user after deletion
        await ref.read(authNotifierProvider.notifier).logout();

        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Account deleted successfully');

          // Navigate to login after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        }
      } catch (error) {
        if (mounted) {
          SnackbarHelper.showError(
              context, error.toString().replaceAll('Exception: ', ''));
        }
      }
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
