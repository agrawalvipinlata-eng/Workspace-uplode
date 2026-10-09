import 'package:flutter/material.dart';
import '../theme/nmb_colors.dart';
import '../theme/nmb_typography.dart';

/// Consistent confirmation dialog. Returns true if confirmed.
Future<bool> showNmbConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon,
                color: destructive ? NmbColors.danger : NmbColors.primary,),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: NmbColors.danger,
                  minimumSize: const Size(110, 46),
                )
              : FilledButton.styleFrom(minimumSize: const Size(110, 46)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Consistent snackbars.
void showNmbSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? NmbColors.danger
            : isSuccess
                ? NmbColors.success
                : NmbColors.textPrimary,
        content: Row(
          children: <Widget>[
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: NmbTypography.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}
