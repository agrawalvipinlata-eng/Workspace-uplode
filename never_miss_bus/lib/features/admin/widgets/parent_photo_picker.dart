import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/nmb_colors.dart';

class ParentPhotoPicker extends StatelessWidget {
  const ParentPhotoPicker({
    super.key,
    required this.label,
    required this.encoded,
    required this.onTap,
  });

  final String label;
  final String? encoded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NmbColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: encoded == null
                    ? null
                    : MemoryImage(base64Decode(encoded!)),
                child: encoded == null
                    ? const Icon(Icons.add_a_photo_rounded)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
              const Text('Album / Camera', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
}
