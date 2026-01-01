import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/auth_providers.dart';
import '/core/providers/employee_providers.dart';

class EmployeeLayoutPage extends ConsumerWidget {
  final Widget child;

  const EmployeeLayoutPage({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final employeeAsync = authState.employeeId != null
        ? ref.watch(employeeByIdProvider(authState.employeeId!))
        : const AsyncValue.data(null);

    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return employeeAsync.when(
      data: (employee) {
        // If employee account is not active, show access denied message
        if (employee != null && !employee.isActive) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.lock,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Access Denied',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your account has been disabled by the administrator.\nPlease contact support for more information.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(authProvider.notifier).logoutEmployee(),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black12.withValues(alpha: .03),
          drawer: isMobile
              ? Drawer(
                  width: 200,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const _EmployeeSideMenu(isDrawer: true),
                )
              : null,
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            shape: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            leading: isMobile
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/employee/dashboard'),
                        child: Row(
                          children: const [
                            Text(
                              'Employee Portal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            leadingWidth: isMobile ? null : 250,
            title: isMobile
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/employee/dashboard'),
                      child: Row(
                        children: const [
                          Text(
                            'Employee Portal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: PopupMenuButton<int>(
                  borderRadius: BorderRadius.circular(32),
                  offset: const Offset(0, 50),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CircleAvatar(
                    backgroundImage: employee?.image.isNotEmpty == true
                        ? NetworkImage(employee!.image)
                        : null,
                    child: employee?.image.isEmpty == true || employee == null
                        ? const Icon(LucideIcons.user, size: 20)
                        : null,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      height: 40,
                      child: Row(
                        children: const [
                          Icon(LucideIcons.user, size: 18),
                          SizedBox(width: 12),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      height: 40,
                      child: Row(
                        children: const [
                          Icon(LucideIcons.settings, size: 18),
                          SizedBox(width: 12),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 3,
                      height: 40,
                      child: Row(
                        children: const [
                          Icon(LucideIcons.helpCircle, size: 18),
                          SizedBox(width: 12),
                          Text('Help & Support'),
                        ],
                      ),
                    ),
                    if (authState.isAdminAuthenticated) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 4,
                        height: 40,
                        child: Row(
                          children: const [
                            Icon(LucideIcons.refreshCcw, size: 18),
                            SizedBox(width: 12),
                            Text('Switch to Admin Portal'),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 0,
                      height: 40,
                      child: Row(
                        children: const [
                          Icon(LucideIcons.logOut, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Sign Out', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 1) {
                      context.go('/employee/profile');
                    } else if (value == 2) {
                      context.go('/employee/settings');
                    } else if (value == 3) {
                      context.go('/employee/support');
                    } else if (value == 4) {
                      context.go('/admin/dashboard');
                    } else if (value == 0) {
                      ref.read(authProvider.notifier).logoutEmployee();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Row(
            children: [
              if (!isMobile) ...[
                const _EmployeeSideMenu(),
                const VerticalDivider(thickness: 1, width: 1),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}

class _EmployeeSideMenu extends StatefulWidget {
  final bool isDrawer;
  const _EmployeeSideMenu({this.isDrawer = false});

  @override
  State<_EmployeeSideMenu> createState() => _EmployeeSideMenuState();
}

class _EmployeeSideMenuState extends State<_EmployeeSideMenu> {
  bool _isExpanded = true;
  bool _isLeaveSubmenuOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-expand Leave menu if we are already on a leave page
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/employee/leave')) {
      _isLeaveSubmenuOpen = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);

    return Container(
      width: widget.isDrawer ? 200 : (_isExpanded ? 200 : 60),
      color: Colors.white,
      padding: EdgeInsets.only(top: widget.isDrawer ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: (widget.isDrawer || _isExpanded)
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.isDrawer) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/employee/dashboard');
                          },
                          child: const Text(
                            'Employee Portal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildNavItem(0, selectedIndex, LucideIcons.home, 'Overview'),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    1,
                    selectedIndex,
                    LucideIcons.calendar,
                    'My Schedule',
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    2,
                    selectedIndex,
                    LucideIcons.users,
                    'My Clients',
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    3,
                    selectedIndex,
                    LucideIcons.bookUp,
                    'Contact',
                  ),
                  const SizedBox(height: 4),
                  // Expandable Leave Menu
                  if (widget.isDrawer || _isExpanded)
                    Column(
                      children: [
                        _buildNavHeader(
                          selectedIndex,
                          [5, 6, 7],
                          LucideIcons.calendarX,
                          'Leave',
                          isOpen: _isLeaveSubmenuOpen,
                          onTap: () {
                            setState(() {
                              _isLeaveSubmenuOpen = !_isLeaveSubmenuOpen;
                            });
                          },
                        ),
                        if (_isLeaveSubmenuOpen) ...[
                          _buildSubNavItem(
                            6,
                            selectedIndex,
                            'Apply Leave',
                            onTap: () => _onDestinationSelected(6, context),
                          ),
                          _buildSubNavItem(
                            5,
                            selectedIndex,
                            'My Leave',
                            onTap: () => _onDestinationSelected(5, context),
                          ),
                          _buildSubNavItem(
                            7,
                            selectedIndex,
                            'Leave Policy',
                            onTap: () => _onDestinationSelected(7, context),
                          ),
                        ],
                      ],
                    )
                  else
                    _buildNavItem(
                      5,
                      selectedIndex,
                      LucideIcons.calendarX,
                      'Leave',
                    ),
                ],
              ),
            ),
          ),
          if (!widget.isDrawer) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: IconButton(
                icon: Icon(
                  _isExpanded
                      ? LucideIcons.chevronsLeft
                      : LucideIcons.chevronsRight,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavHeader(
    int selectedIndex,
    List<int> subIndices,
    IconData icon,
    String label, {
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    final isAnySubSelected = subIndices.contains(selectedIndex);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isAnySubSelected
              ? theme.colorScheme.secondary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                icon,
                size: 18,
                color: isAnySubSelected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isAnySubSelected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontWeight: isAnySubSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                isOpen ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubNavItem(
    int index,
    int selectedIndex,
    String label, {
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        onTap();
        if (widget.isDrawer) {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(50, 10, 16, 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected
                ? theme.colorScheme.secondary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    int selectedIndex,
    IconData icon,
    String label,
  ) {
    final isSelected = index == selectedIndex;
    final theme = Theme.of(context);
    final bool showLabel = widget.isDrawer || _isExpanded;

    return InkWell(
      onTap: () {
        _onDestinationSelected(index, context);
        if (widget.isDrawer) {
          Navigator.pop(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? theme.colorScheme.secondary
                  : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (showLabel)
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/employee/dashboard')) return 0;
    if (location.startsWith('/employee/schedule')) return 1;
    if (location.startsWith('/employee/clients')) return 2;
    if (location.startsWith('/employee/contact')) return 3;
    if (location == '/employee/leave') return 5;
    if (location == '/employee/leave/apply') return 6;
    if (location == '/employee/leave/policy') return 7;
    return 0;
  }

  void _onDestinationSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/employee/dashboard');
        break;
      case 1:
        context.go('/employee/schedule');
        break;
      case 2:
        context.go('/employee/clients');
        break;
      case 3:
        context.go('/employee/contact');
        break;
      case 5:
        context.go('/employee/leave');
        break;
      case 6:
        context.go('/employee/leave/apply');
        break;
      case 7:
        context.go('/employee/leave/policy');
        break;
    }
  }
}
