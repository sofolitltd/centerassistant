import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/models/employee.dart';
import '/core/providers/employee_providers.dart';
import '../../../leaves/presentation/pages/leave_page.dart';
import '../../../schedule/presentation/pages/home/schedule_specific_page.dart';
import 'employee_information_page.dart';

class EmployeeDetailsPage extends ConsumerStatefulWidget {
  final String employeeId;
  final String initialTab;

  const EmployeeDetailsPage({
    super.key,
    required this.employeeId,
    this.initialTab = 'details',
  });

  @override
  ConsumerState<EmployeeDetailsPage> createState() =>
      _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends ConsumerState<EmployeeDetailsPage> {
  void _onTabChanged(String tab) {
    context.go('/admin/employees/${widget.employeeId}/$tab');
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      body: employeesAsync.when(
        data: (employees) {
          final employee = employees
              .where((e) => e.id == widget.employeeId)
              .firstOrNull;
          if (employee == null) {
            return const Center(child: Text('Employee not found.'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    InkWell(
                      onTap: () => context.go('/admin/dashboard'),
                      child: const Text(
                        'Admin',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    InkWell(
                      onTap: () => context.go('/admin/employees'),
                      child: const Text(
                        'Employees',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Switcher
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: _buildTabSwitcher(),
              ),

              // Content Area
              Expanded(child: _buildTabContent(employee)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _TabButton(
            label: 'Details',
            isSelected: widget.initialTab == 'details',
            onTap: () => _onTabChanged('details'),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Schedule',
            isSelected: widget.initialTab == 'schedule',
            onTap: () => _onTabChanged('schedule'),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'Leave',
            isSelected: widget.initialTab == 'leave',
            onTap: () => _onTabChanged('leave'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Employee employee) {
    switch (widget.initialTab) {
      case 'details':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: EmployeeInformationPage(employee: employee),
        );
      case 'schedule':
        return ScheduleSpecificPage(employeeId: employee.id);
      case 'leave':
        return LeavePage(entityId: employee.id, entityName: employee.name);
      default:
        return const SizedBox();
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
