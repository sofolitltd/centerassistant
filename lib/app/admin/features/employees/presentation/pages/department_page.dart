import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/employee_providers.dart';

class DepartmentManagementPage extends ConsumerStatefulWidget {
  const DepartmentManagementPage({super.key});

  @override
  ConsumerState<DepartmentManagementPage> createState() =>
      _DepartmentManagementPageState();
}

class _DepartmentManagementPageState
    extends ConsumerState<DepartmentManagementPage> {
  bool _showDepartments = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deptsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 24),
            _buildActionTabs(theme),
            const SizedBox(height: 24),
            _showDepartments
                ? _buildDepartmentSection(theme)
                : _buildDesignationSection(theme, deptsAsync),
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
          const SizedBox(width: 12),
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
            const Text('Settings', style: TextStyle(color: Colors.grey)),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            const Text('Departments'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Departments',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Departments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDepartmentDialog(),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Department'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('departments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                return SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columnSpacing: 24,
                    border: TableBorder.all(color: Colors.grey.shade200),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Schedulable',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] as String;
                      final isSchedulable =
                          data['isSchedulable'] as bool? ?? false;

                      return DataRow(
                        cells: [
                          DataCell(Text(name)),
                          DataCell(
                            Text(
                              isSchedulable ? 'Yes' : 'No',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isSchedulable
                                    ? const Color(0xFF3D5A45)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.edit2,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showEditDialog(
                                    'departments',
                                    name,
                                    docId: doc.id,
                                    currentSchedulable: isSchedulable,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _delete('departments', doc.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Designations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDesignationDialog(deptsAsync),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add Designation'),
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
                return SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columnSpacing: 24,
                    border: TableBorder.all(color: Colors.grey.shade200),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Designation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Department',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'];
                      final dept = data['department'] ?? 'No Department';

                      return DataRow(
                        cells: [
                          DataCell(Text(name)),
                          DataCell(Text(dept)),
                          DataCell(
                            Row(
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
                                    name,
                                    docId: doc.id,
                                    currentDepartment: dept,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _delete('designations', doc.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDepartmentDialog() async {
    final controller = TextEditingController();
    bool isSchedulable = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Add New Department'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: _inputDecoration(hint: 'Department Name'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Schedulable'),
                  subtitle: const Text(
                    'Allow this department in the scheduler',
                  ),
                  value: isSchedulable,
                  onChanged: (val) => setDialogState(() => isSchedulable = val),
                  activeColor: const Color(0xFF3D5A45),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _addDepartment(name, isSchedulable);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDesignationDialog(
    AsyncValue<List<String>> deptsAsync,
  ) async {
    final controller = TextEditingController();
    String? localSelectedDept;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Add New Designation'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                deptsAsync.when(
                  data: (depts) => DropdownButtonFormField<String>(
                    value: localSelectedDept,
                    hint: const Text('Select Department'),
                    items: depts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => localSelectedDept = v),
                    decoration: _inputDecoration(),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading departments'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: _inputDecoration(hint: 'Designation Name'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty && localSelectedDept != null) {
                  _addDesignation(name, localSelectedDept!);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    String collection,
    String currentName, {
    String? docId,
    bool? currentSchedulable,
    String? currentDepartment,
  }) async {
    final controller = TextEditingController(text: currentName);
    bool localSchedulable = currentSchedulable ?? false;
    String? localDept = currentDepartment;
    final deptsAsync = ref.read(departmentsProvider);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Edit ${collection.substring(0, collection.length - 1)}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (collection == 'designations') ...[
                  deptsAsync.when(
                    data: (depts) => DropdownButtonFormField<String>(
                      value: depts.contains(localDept) ? localDept : null,
                      hint: const Text('Select Department'),
                      items: depts
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => localDept = v),
                      decoration: _inputDecoration(),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading departments'),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: controller,
                  decoration: _inputDecoration(hint: 'Enter name'),
                ),
                if (collection == 'departments') ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Schedulable'),
                    value: localSchedulable,
                    onChanged: (val) =>
                        setDialogState(() => localSchedulable = val),
                    activeColor: const Color(0xFF3D5A45),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;

                final firestore = FirebaseFirestore.instance;
                if (collection == 'departments') {
                  await firestore.collection('departments').doc(docId).update({
                    'name': newName,
                    'isSchedulable': localSchedulable,
                  });

                  // Cascade update to designations if name changed
                  if (newName != currentName) {
                    final desigSnapshot = await firestore
                        .collection('designations')
                        .where('department', isEqualTo: currentName)
                        .get();
                    for (var doc in desigSnapshot.docs) {
                      await doc.reference.update({'department': newName});
                    }
                  }
                  ref.invalidate(departmentsProvider);
                  ref.invalidate(designationsProvider);
                } else {
                  await firestore.collection('designations').doc(docId).update({
                    'name': newName,
                    'department': localDept,
                  });
                  ref.invalidate(designationsProvider);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
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

  Future<void> _addDepartment(String name, bool isSchedulable) async {
    await FirebaseFirestore.instance.collection('departments').add({
      'name': name,
      'isSchedulable': isSchedulable,
    });
    ref.invalidate(departmentsProvider);
  }

  Future<void> _addDesignation(String name, String dept) async {
    await FirebaseFirestore.instance.collection('designations').add({
      'name': name,
      'department': dept,
    });
    ref.invalidate(designationsProvider);
  }

  Future<void> _delete(String collection, String docId) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
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
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(4),
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
