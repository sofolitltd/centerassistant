import 'package:flutter/material.dart';

import '/core/providers/session_providers.dart';

class CompactCard extends StatelessWidget {
  final SessionCardData session;
  const CompactCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: .all(color: Colors.grey, width: .8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        session.displayNickName.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          height: 1.25,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
