import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/employee.dart';

class EmployeeInformationPage extends StatelessWidget {
  final Employee employee;

  const EmployeeInformationPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              children: [
                _buildProfileHeader(context),
                const SizedBox(height: 16),
                _buildBasicInfo(context),
                const SizedBox(height: 16),
                _buildEmploymentInfo(context),
                const SizedBox(height: 16),
                _buildContactInfo(context),
                const SizedBox(height: 16),
                _buildEducationSection(context),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildProfileHeader(context),
                      const SizedBox(height: 16),
                      _buildBasicInfo(context),
                      const SizedBox(height: 16),
                      _buildEmploymentInfo(context),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildContactInfo(context),
                      const SizedBox(height: 16),
                      _buildEducationSection(context),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: .circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: employee.image.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    spacing: 12,
                    children: [
                      //
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'ID: ${employee.employeeId}',
                          style: TextStyle(fontSize: 12, fontWeight: .bold),
                        ),
                      ),

                      //
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: employee.isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: employee.isActive
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          employee.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: employee.isActive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${employee.department.toUpperCase()}  • ${employee.designation}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return _buildSectionCard('Basic Information', [
      _buildInfoGrid([
        _buildInfoItem('Full Name', employee.name),
        _buildInfoItem('Nick Name', employee.nickName),
        _buildInfoItem('Gender', employee.gender.toUpperCase()),
        _buildInfoItem(
          'Date of Birth',
          employee.dateOfBirth != null
              ? DateFormat('MMM dd, yyyy').format(employee.dateOfBirth!)
              : 'N/A',
        ),
        _buildInfoItem('NID Number', employee.nid),
        _buildInfoItem('TIN Number', employee.tin),
      ]),
    ]);
  }

  Widget _buildEmploymentInfo(BuildContext context) {
    return _buildSectionCard('Professional & Employment', [
      _buildInfoGrid([
        _buildInfoItem('Employee ID', employee.employeeId),
        _buildInfoItem('Department', employee.department.toUpperCase()),
        _buildInfoItem('Designation', employee.designation),
        _buildInfoItem(
          'Joined Date',
          DateFormat('MMM dd, yyyy').format(employee.joinedDate),
        ),
        _buildInfoItem(
          'Separation Date',
          employee.separationDate != null
              ? DateFormat('MMM dd, yyyy').format(employee.separationDate!)
              : 'N/A',
        ),
      ]),
    ]);
  }

  Widget _buildContactInfo(BuildContext context) {
    return _buildSectionCard('Contact Information', [
      _buildInfoGrid([
        _buildInfoItem('Personal Phone', employee.personalPhone),
        _buildInfoItem('Official Phone', employee.officialPhone),
        _buildInfoItem('Personal Email', employee.personalEmail),
        _buildInfoItem('Official Email', employee.officialEmail),
      ]),
      const SizedBox(height: 16),
      _buildInfoItem('Present Address', employee.presentAddress),
      const SizedBox(height: 16),
      _buildInfoItem('Permanent Address', employee.permanentAddress),
    ]);
  }

  Widget _buildEducationSection(BuildContext context) {
    return _buildSectionCard('Education', [
      if (employee.education.isEmpty)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No academic records found',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        )
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: employee.education.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final edu = employee.education[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.graduationCap,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu.degree,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          edu.institute,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    edu.passingYear,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    ]);
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: children.map((w) => SizedBox(width: 200, child: w)).toList(),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
