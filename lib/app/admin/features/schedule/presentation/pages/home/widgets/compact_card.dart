import 'package:flutter/material.dart';

import '/core/providers/session_providers.dart';

class CompactCard extends StatelessWidget {
  final SessionCardData session;
  const CompactCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: .all(color: Colors.grey, width: .8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        session.displayNickName.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          height: 1.25,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
