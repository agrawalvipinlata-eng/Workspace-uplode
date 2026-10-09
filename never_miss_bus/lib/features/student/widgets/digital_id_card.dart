import 'package:flutter/material.dart';

import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../shared/student_avatar.dart';

/// DIGITAL SCHOOL ID CARD — real plastic ID jaisa design.
/// Emergency me kaam aata hai: photo, blood group, class, bus, contact.
/// Bachha bus me phone dikhake identity prove kar sakta hai.
class DigitalIdCard extends StatelessWidget {
  const DigitalIdCard({super.key, required this.student, this.bus});

  final AppUser student;
  final Bus? bus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1A3FA0), Color(0xFF2557D6)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x3317233B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // ── Header strip ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: NmbColors.accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: <Widget>[
                ClipOval(
                  child: Image.asset(
                    'assets/images/school_logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_bus_rounded,
                        color: Color(0xFF5B3C00),
                        size: 20,),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    NmbConstants.schoolName.toUpperCase(),
                    style: NmbTypography.caption.copyWith(
                      color: const Color(0xFF5B3C00),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  'STUDENT ID',
                  style: NmbTypography.caption.copyWith(
                    color: const Color(0xFF5B3C00),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                // Photo
                StudentAvatar(user: student, radius: 38),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        student.fullName,
                        style: NmbTypography.sectionTitle
                            .copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _idRow('Class',
                          '${student.classSection ?? '—'}  •  Roll ${student.rollNumber ?? '—'}',),
                      if (bus != null) _idRow('Bus', bus!.busNumber),
                      if (student.bloodGroup != null)
                        _idRow('Blood', student.bloodGroup!),
                      if (student.admissionNumber != null)
                        _idRow('Adm No', student.admissionNumber!),
                    ],
                  ),
                ),
                // Blood group emergency badge
                if (student.bloodGroup != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8,),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Text('🩸', style: TextStyle(fontSize: 18)),
                        Text(
                          student.bloodGroup!,
                          style: NmbTypography.cardTitle.copyWith(
                            color: NmbColors.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Footer ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.verified_rounded,
                    color: NmbColors.accent, size: 16,),
                const SizedBox(width: 6),
                Text(
                  'Verified by school • Never Miss Bus',
                  style: NmbTypography.caption
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 55,
            child: Text(label,
                style: NmbTypography.caption
                    .copyWith(color: Colors.white60),),
          ),
          Expanded(
            child: Text(
              value,
              style: NmbTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
