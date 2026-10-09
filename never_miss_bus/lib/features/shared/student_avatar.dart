import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';
import '../../models/app_user.dart';

/// Student photo avatar — photo ho toh photo, warna initial letter.
/// Base64 decode cached rehta hai (memory-friendly).
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.user,
    this.radius = 30,
    this.borderColor,
    this.showOnlineDot = false,
    this.online = false,
  });

  final AppUser user;
  final double radius;
  final Color? borderColor;
  final bool showOnlineDot;
  final bool online;

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  Uint8List? _bytes() {
    final String? b64 = user.photoB64;
    if (b64 == null || b64.isEmpty) return null;
    final String key = '${user.uid}_${b64.length}';
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final Uint8List bytes = base64Decode(b64);
      if (_cache.length > 60) _cache.clear();
      _cache[key] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _bytes();

    final Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: borderColor ?? Colors.white,
      child: CircleAvatar(
        radius: radius - 3,
        backgroundColor: NmbColors.primarySoft,
        backgroundImage: bytes != null ? MemoryImage(bytes) : null,
        child: bytes == null
            ? Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : '?',
                style: NmbTypography.displayTitle.copyWith(
                  color: NmbColors.primary,
                  fontSize: radius * 0.8,
                ),
              )
            : null,
      ),
    );

    if (!showOnlineDot) return avatar;
    return Stack(
      children: <Widget>[
        avatar,
        Positioned(
          bottom: radius * 0.08,
          right: radius * 0.08,
          child: Container(
            width: radius * 0.4,
            height: radius * 0.4,
            decoration: BoxDecoration(
              color: online ? NmbColors.success : NmbColors.textTertiary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
