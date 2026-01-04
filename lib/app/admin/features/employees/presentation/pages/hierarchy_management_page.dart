import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/employee_providers.dart';

class HierarchyManagementPage extends ConsumerStatefulWidget {
  const HierarchyManagementPage({super.key});

  @override
  ConsumerState<HierarchyManagementPage> createState() =>
      _HierarchyManagementPageState();
}

class _HierarchyManagementPageState
    extends ConsumerState<HierarchyManagementPage> {
  final _deptController = TextEditingController();
  final _desigController = TextEditingController();
  String? _selectedDept;
  bool _showDepartments = true;

  @override
  void dispose() {
    _deptController.dispose();
    _desigController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deptsAsync = ref.watch(departmentsProvider);
    final desigsAsync = ref.watch(designationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 32),
            _buildActionTabs(theme),
            const SizedBox(height: 24),
            _showDepartments
                ? _buildDepartmentSection(theme)
                : _buildDesignationSection(theme, deptsAsync, desigsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTabs(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabButton(
            label: 'Departments',
            isSelected: _showDepartments,
            onTap: () => setState(() => _showDepartments = true),
          ),
          const SizedBox(width: 4),
          _TabButton(
            label: 'Designations',
            isSelected: !_showDepartments,
            onTap: () => setState(() => _showDepartments = false),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => context.go('/admin/dashboard'),
              child: const Text('Admin', style: TextStyle(color: Colors.grey)),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              onTap: () => context.go('/admin/employees'),
              child: const Text(
                'Employees',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            const Text('Department and Designation'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Department & Designation',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSection(ThemeData theme) {
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
                Expanded(
                  child: TextField(
                    controller: _deptController,
                    decoration: _inputDecoration(hint: 'New Department Name'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _addDepartment(),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Dept'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('departments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final name = data['name'] as String;
                    final isSchedulable =
                        data['isSchedulable'] as bool? ?? false;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        isSchedulable
                            ? 'Appears in Scheduler'
                            : 'Not in Scheduler',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSchedulable ? Colors.green : Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Schedulable',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              SizedBox(
                                height: 30,
                                child: FittedBox(
                                  child: Switch(
                                    value: isSchedulable,
                                    onChanged: (val) =>
                                        _toggleSchedulable(docs[i].id, val),
                                    activeColor: Colors.green,
                                    materialTapTargetSize: .shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.edit2,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () => _showEditDialog(
                              'departments',
                              name,
                              docId: docs[i].id,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => _delete('departments', name),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignationSection(
    ThemeData theme,
    AsyncValue<List<String>> deptsAsync,
    AsyncValue<List<String>> desigsAsync,
  ) {
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
                Expanded(
                  flex: 2,
                  child: deptsAsync.when(
                    data: (depts) => DropdownButtonFormField<String>(
                      value: _selectedDept,
                      hint: const Text('Select Dept'),
                      items: depts
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDept = v),
                      decoration: _inputDecoration(),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _desigController,
                    decoration: _inputDecoration(hint: 'Designation Name'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _addDesignation(),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('designations')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        data['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        data['department'] ?? 'No Department',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              LucideIcons.edit2,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () => _showEditDialog(
                              'designations',
                              data['name'],
                              docId: docs[i].id,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('designations')
                                .doc(docs[i].id)
                                .delete(),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSchedulable(String docId, bool value) async {
    await FirebaseFirestore.instance
        .collection('departments')
        .doc(docId)
        .update({'isSchedulable': value});
  }

  Future<void> _showEditDialog(
    String collection,
    String currentName, {
    String? docId,
  }) async {
    final controller = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Edit ${collection.substring(0, collection.length - 1)}'),
        content: TextField(
          controller: controller,
          decoration: _inputDecoration(hint: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final newName = controller.text.trim();
      final firestore = FirebaseFirestore.instance;

      if (collection == 'departments') {
        await firestore.collection('departments').doc(docId).update({
          'name': newName,
        });

        // Cascade update to designations
        final desigSnapshot = await firestore
            .collection('designations')
            .where('department', isEqualTo: currentName)
            .get();
        for (var doc in desigSnapshot.docs) {
          await doc.reference.update({'department': newName});
        }
        ref.invalidate(departmentsProvider);
        ref.invalidate(designationsProvider);
      } else {
        await firestore.collection('designations').doc(docId).update({
          'name': newName,
        });
        ref.invalidate(designationsProvider);
      }
    }
  }

  Future<void> _addDepartment() async {
    final name = _deptController.text.trim();
    if (name.isEmpty) return;
    await FirebaseFirestore.instance.collection('departments').add({
      'name': name,
      'isSchedulable': true, // Default to true for new depts
    });
    _deptController.clear();
    ref.invalidate(departmentsProvider);
  }

  Future<void> _addDesignation() async {
    final name = _desigController.text.trim();
    if (name.isEmpty || _selectedDept == null) return;
    await FirebaseFirestore.instance.collection('designations').add({
      'name': name,
      'department': _selectedDept,
    });
    _desigController.clear();
    ref.invalidate(designationsProvider);
  }

  Future<void> _delete(String collection, String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('name', isEqualTo: name)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    if (collection == 'departments') ref.invalidate(departmentsProvider);
    if (collection == 'designations') ref.invalidate(designationsProvider);
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D5A45) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
