import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/auth_providers.dart';
import '/core/providers/employee_providers.dart';

class EmployeeSettingsPage extends ConsumerStatefulWidget {
  const EmployeeSettingsPage({super.key});

  @override
  ConsumerState<EmployeeSettingsPage> createState() =>
      _EmployeeSettingsPageState();
}

class _EmployeeSettingsPageState extends ConsumerState<EmployeeSettingsPage> {
  final _passwordFormKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEmailLoading = false;
  bool _isPasswordLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _selectedEmailOption;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateEmail(String userId, String email) async {
    setState(() => _isEmailLoading = true);
    try {
      await ref.read(employeeAuthRepositoryProvider).changeEmail(userId, email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login email updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _handleUpdatePassword(
    String userId,
    String currentDbPassword,
  ) async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (_currentPasswordController.text != currentDbPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password is incorrect')),
      );
      return;
    }

    setState(() => _isPasswordLoading = true);
    try {
      await ref
          .read(employeeAuthRepositoryProvider)
          .changePassword(userId, _newPasswordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final employeeAsync = authState.employeeId != null
        ? ref.watch(employeeByIdProvider(authState.employeeId!))
        : const AsyncValue.data(null);

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/employee/dashboard'),
                      child: Text(
                        'Overview',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    Text('Settings', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Account Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your portal credentials and security preferences.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),

                employeeAsync.when(
                  data: (employee) {
                    if (employee == null) {
                      return const Center(
                        child: Text('Employee data not found'),
                      );
                    }

                    _selectedEmailOption ??= employee.email;

                    final hasOfficial = employee.officialEmail.isNotEmpty;
                    final hasPersonal = employee.personalEmail.isNotEmpty;

                    return Column(
                      children: [
                        _buildSettingsCard(
                          title: 'Login Email',
                          subtitle: 'Choose which email to use for login',
                          icon: LucideIcons.mail,
                          form: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Login Email:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                employee.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (hasOfficial)
                                _buildEmailOption(
                                  label: 'Official Email',
                                  email: employee.officialEmail,
                                  theme: theme,
                                ),
                              if (hasPersonal)
                                _buildEmailOption(
                                  label: 'Personal Email',
                                  email: employee.personalEmail,
                                  theme: theme,
                                ),

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      (_isEmailLoading ||
                                          _selectedEmailOption ==
                                              employee.email)
                                      ? null
                                      : () => _handleUpdateEmail(
                                          employee.id,
                                          _selectedEmailOption!,
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                  ),
                                  child: _isEmailLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Update Login Email'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        _buildSettingsCard(
                          title: 'Security',
                          subtitle: 'Update your portal password',
                          icon: LucideIcons.shieldCheck,
                          form: Form(
                            key: _passwordFormKey,
                            child: Column(
                              children: [
                                _buildPasswordField(
                                  label: 'Current Password',
                                  controller: _currentPasswordController,
                                  obscure: _obscureCurrent,
                                  onToggle: () => setState(
                                    () => _obscureCurrent = !_obscureCurrent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  label: 'New Password',
                                  controller: _newPasswordController,
                                  obscure: _obscureNew,
                                  onToggle: () => setState(
                                    () => _obscureNew = !_obscureNew,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  label: 'Confirm New Password',
                                  controller: _confirmPasswordController,
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    if (v != _newPasswordController.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isPasswordLoading
                                        ? null
                                        : () => _handleUpdatePassword(
                                            employee.id,
                                            employee.password,
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      foregroundColor:
                                          theme.colorScheme.onSecondary,
                                    ),
                                    child: _isPasswordLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Change Password'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailOption({
    required String label,
    required String email,
    required ThemeData theme,
  }) {
    return RadioListTile<String>(
      value: email,
      groupValue: _selectedEmailOption,
      onChanged: (v) => setState(() => _selectedEmailOption = v),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        email,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: theme.colorScheme.primary,
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget form,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 40),
            form,
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 18,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator:
              validator ?? (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
