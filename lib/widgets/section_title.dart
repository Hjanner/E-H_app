import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  
  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }
} 