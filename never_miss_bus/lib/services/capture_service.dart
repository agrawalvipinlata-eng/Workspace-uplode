import 'dart:typed_data';

import 'package:screenshot/screenshot.dart';

/// Shared capture state for the signed-in shell.
/// The shell wraps the current route, so a screenshot taken before opening the
/// Capture & Report screen represents the actual screen the user was viewing.
class CaptureService {
  CaptureService._();

  static final ScreenshotController controller = ScreenshotController();
  static Uint8List? lastScreenshot;
  static String? lastRecordingPath;

  static Future<Uint8List?> captureCurrent({double? pixelRatio}) async {
    try {
      lastScreenshot = await controller.capture(
        delay: const Duration(milliseconds: 80),
        pixelRatio: pixelRatio,
      );
      return lastScreenshot;
    } catch (_) {
      return null;
    }
  }
}
