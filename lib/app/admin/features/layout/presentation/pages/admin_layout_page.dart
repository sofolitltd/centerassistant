import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/auth_providers.dart';

class AdminLayoutPage extends ConsumerWidget {
  final Widget child;

  const AdminLayoutPage({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return Scaffold(
      backgroundColor: Colors.black12.withValues(alpha: .03),
      drawer: isMobile
          ? Drawer(
              width: 200,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: const _SideMenu(isDrawer: true),
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
            ? null // Scaffold will automatically add menu icon
            : Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/admin/dashboard'),
                    child: Row(
                      children: const [
                        Text(
                          'Center Assistant',
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
                  onTap: () => context.go('/admin/dashboard'),
                  child: Row(
                    children: const [
                      Text(
                        'Center Assistant',
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
              child: const CircleAvatar(
                child: Icon(LucideIcons.user, size: 20),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Management',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  height: 40,

                  child: Row(
                    children: const [
                      Icon(LucideIcons.user, size: 18),
                      SizedBox(width: 12),
                      Text('My Profile'),
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
                ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 3,
                    child: Row(
                      children: const [
                        Icon(LucideIcons.refreshCcw, size: 18),
                        SizedBox(width: 12),
                        Text('Switch to Employee Portal'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 0,
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
                if (value == 0) {
                  ref.read(authProvider.notifier).logout();
                } else if (value == 3) {
                  context.go('/employee/dashboard');
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
            const _SideMenu(),
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
  }
}

class _SideMenu extends StatefulWidget {
  final bool isDrawer;
  const _SideMenu({this.isDrawer = false});

  @override
  State<_SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<_SideMenu> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Container(
      width: widget.isDrawer ? 200 : (_isExpanded ? 200 : 60),
      color: Colors.white,
      padding: .only(top: widget.isDrawer ? 0 : 16),
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
                            context.go('/admin/dashboard');
                          },
                          child: Row(
                            children: const [
                              Text(
                                'Center Assistant',
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
                    const SizedBox(height: 24),
                  ],
                  _buildNavItem(0, selectedIndex, LucideIcons.home, 'Overview'),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    1,
                    selectedIndex,
                    LucideIcons.calendar,
                    'Schedule',
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    2,
                    selectedIndex,
                    LucideIcons.users,
                    'Employees',
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    3,
                    selectedIndex,
                    LucideIcons.contact,
                    'Clients',
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    4,
                    selectedIndex,
                    LucideIcons.clock,
                    'Time Slots',
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
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
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
                    ? theme.colorScheme.primary
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
                        ? theme.colorScheme.primary
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
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/schedule')) return 1;
    if (location.startsWith('/admin/employees')) return 2;
    if (location.startsWith('/admin/clients')) return 3;
    if (location.startsWith('/admin/time-slots')) return 4;
    return 0;
  }

  void _onDestinationSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/schedule');
        break;
      case 2:
        context.go('/admin/employees');
        break;
      case 3:
        context.go('/admin/clients');
        break;
      case 4:
        context.go('/admin/time-slots');
        break;
    }
  }
}
