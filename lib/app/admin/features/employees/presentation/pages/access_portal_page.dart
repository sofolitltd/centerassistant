import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '/core/providers/employee_providers.dart';

class AccessPortalPage extends ConsumerStatefulWidget {
  final String? userId;
  const AccessPortalPage({super.key, this.userId});

  @override
  ConsumerState<AccessPortalPage> createState() => _InviteEmployeePageState();
}

class _InviteEmployeePageState extends ConsumerState<AccessPortalPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedClientId;
  bool _isManualEntry = true;
  String _selectedEmailType = 'official'; // 'personal' or 'official'

  @override
  void initState() {
    super.initState();
    _generatePassword();
    // Pre-select employee if userId is provided
    if (widget.userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedClientId = widget.userId;
          _isManualEntry = false;
        });
        // Load employee data to populate email
        _loadEmployeeData(widget.userId!);
      });
    }
  }

  Future<void> _loadEmployeeData(String userId) async {
    final employees = ref.read(employeesProvider).value ?? [];
    final employee = employees.firstWhere(
      (e) => e.id == userId,
      orElse: () => employees.first,
    );
    if (employee.id == userId) {
      setState(() {
        // If employee has portal access, load current login email
        if (employee.email.isNotEmpty) {
          _emailController.text = employee.email;
          // Detect which email type is being used
          if (employee.email == employee.officialEmail) {
            _selectedEmailType = 'official';
          } else if (employee.email == employee.personalEmail) {
            _selectedEmailType = 'personal';
          } else {
            // Custom email, default to official
            _selectedEmailType = 'official';
          }
        } else {
          // No portal access yet, use official email by default
          _emailController.text = employee.officialEmail.isNotEmpty
              ? employee.officialEmail
              : employee.personalEmail;
          _selectedEmailType = employee.officialEmail.isNotEmpty
              ? 'official'
              : 'personal';
        }

        // SECURITY: We never fetch the existing password for display.
        // A new one is already generated in initState or via the refresh button.
      });
    }
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final password = List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    setState(() {
      _passwordController.text = password;
    });
  }

  Future<void> _inviteEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog before updating
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: .zero,
        title: Container(
          constraints: const BoxConstraints(minWidth: 350, maxWidth: 500),
          child: const Text('Confirm Portal Update'),
        ),
        content: const Text(
          'Are you sure you want to update the portal access for this employee? '
          'The existing password will be overwritten and they will be required to change it upon login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Use existing ID if a client was selected, otherwise generate new
      final String employeeId = _selectedClientId ?? const Uuid().v4();

      // Get name from selected employee or default
      if (_selectedClientId != null) {
        final employees = ref.read(employeesProvider).value ?? [];
        employees.firstWhere((e) => e.id == _selectedClientId);
      }

      // Prepare updates
      final Map<String, dynamic> updates = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'mustChangePassword': true,
        'isActive': true,
      };

      // Save credentials directly to Firestore
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(employeeId)
          .update(updates);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Portal Access Updated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The employee credentials have been updated and access is enabled.',
            ),
            const SizedBox(height: 16),
            const Text(
              'New Credentials:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Email: ${_emailController.text}'),
            Text('Password: ${_passwordController.text}'),
            const SizedBox(height: 12),
            const Text(
              'Note: The employee will be required to change this password on their next login.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: _sendInviteEmail,
            icon: const Icon(LucideIcons.mail, size: 18),
            label: const Text('Share via Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInviteEmail() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final subject = Uri.encodeComponent(
      'Your Employee Portal Access Credentials',
    );
    final body = Uri.encodeComponent(
      'Hello,\n\n'
      'Your portal access credentials for Center Assistant have been set up/updated.\n\n'
      'Login Credentials:\n'
      'Email: $email\n'
      'Password: $password\n\n'
      'Important: You will be required to change your password upon your next login.\n\n'
      'Best regards,\n'
      'Administration',
    );

    final url = Uri.parse('mailto:$email?subject=$subject&body=$body');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/admin/layout'),
                  child: Text(
                    'Admin',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                InkWell(
                  onTap: () => context.go('/admin/employees'),
                  child: Text(
                    'Employees',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('Manage Portal', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                final employeesAsync = ref.watch(employeesProvider);
                return employeesAsync.when(
                  data: (employees) {
                    final employee = _selectedClientId != null
                        ? employees.firstWhere(
                            (e) => e.id == _selectedClientId,
                            orElse: () => employees.first,
                          )
                        : null;
                    final hasAccess = employee?.hasPortalAccess ?? false;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAccess
                              ? 'Manage Portal Access'
                              : 'Grant Portal Access',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasAccess
                              ? 'Update login credentials. For security, existing passwords cannot be viewed.'
                              : 'Grant portal login access to an employee by setting up their credentials.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Text(
                    'Add Portal Access',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  error: (_, _) => Text(
                    'Add Portal Access',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedClientId != null)
                        Consumer(
                          builder: (context, ref, _) {
                            final employeesAsync = ref.watch(employeesProvider);
                            return employeesAsync.when(
                              data: (employees) {
                                final employee = employees.firstWhere(
                                  (e) => e.id == _selectedClientId,
                                  orElse: () => employees.first,
                                );
                                if (employee.id != _selectedClientId) {
                                  return const SizedBox();
                                }
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage:
                                            employee.image.isNotEmpty
                                            ? NetworkImage(employee.image)
                                            : null,
                                        child: employee.image.isEmpty
                                            ? const Icon(Icons.person, size: 30)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              employee.name,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              employee.department,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey.shade600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'ID: ${employee.id}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey.shade500,
                                                    fontFamily: 'monospace',
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (employee.hasPortalAccess)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Colors.green.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Has Access',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (e, s) =>
                                  const Text('Error loading employee'),
                            );
                          },
                        ),
                      if (_selectedClientId != null) const SizedBox(height: 24),
                      if (_selectedClientId != null) ...[
                        const Text(
                          'Select Login Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<String>(
                          groupValue: _selectedEmailType,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedEmailType = value!;

                              // Centralized logic to update the controller based on selection
                              if (_selectedClientId != null) {
                                final employees =
                                    ref.read(employeesProvider).value ?? [];
                                final selected = employees.firstWhere(
                                  (e) => e.id == _selectedClientId,
                                );

                                _emailController.text = (value == 'official')
                                    ? selected.officialEmail
                                    : selected.personalEmail;
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<String>(value: 'official'),
                                    const Text('Official'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<String>(value: 'personal'),
                                    const Text('Personal'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Email Address',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        readOnly: !_isManualEntry,
                        decoration: const InputDecoration(
                          hintText: 'email@example.com',
                          prefixIcon: Icon(LucideIcons.mail, size: 18),
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Temporary Password',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              readOnly: false,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  LucideIcons.lock,
                                  size: 18,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(LucideIcons.copy, size: 18),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: _passwordController.text,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password copied to clipboard',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: _generatePassword,
                            icon: const Icon(LucideIcons.refreshCw, size: 18),
                            tooltip: 'Regenerate Random Password',
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _inviteEmployee,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.userCheck),
                          label: Text(
                            _isLoading ? 'Saving...' : 'Update Portal Access',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
