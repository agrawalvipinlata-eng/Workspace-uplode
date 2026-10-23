import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';
import '../../core/widgets/nmb_card.dart';
import '../../core/widgets/responsive_scaffold_body.dart';
import '../../services/capture_service.dart';

class CaptureReportScreen extends StatefulWidget {
  const CaptureReportScreen({super.key});

  @override
  State<CaptureReportScreen> createState() => _CaptureReportScreenState();
}

class _CaptureReportScreenState extends State<CaptureReportScreen> {
  Uint8List? _screenshot;
  String? _recordingPath;
  bool _recording = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _screenshot = CaptureService.lastScreenshot;
    _recordingPath = CaptureService.lastRecordingPath;
  }

  Future<void> _captureCurrent() async {
    setState(() => _working = true);
    final Uint8List? image = await CaptureService.captureCurrent(
      pixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    if (!mounted) return;
    setState(() {
      _screenshot = image;
      _working = false;
    });
    _message(
      image == null ? 'Screenshot नहीं लिया जा सका.' : 'Screenshot तैयार है.',
      error: image == null,
    );
  }

  Future<File?> _writeScreenshot() async {
    final Uint8List? bytes = _screenshot;
    if (bytes == null) return null;
    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      '${dir.path}/nmb_screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _shareScreenshot() async {
    final File? file = await _writeScreenshot();
    if (file == null) {
      _message('पहले screenshot लें.', error: true);
      return;
    }
    await Share.shareXFiles(
      <XFile>[XFile(file.path)],
      text: 'Never Miss Bus app screenshot',
      subject: 'Never Miss Bus screenshot',
    );
  }

  Future<void> _startRecording() async {
    if (_recording) return;
    try {
      final bool started = await FlutterScreenRecording.startRecordScreen(
        'nmb_issue_${DateTime.now().millisecondsSinceEpoch}',
        titleNotification: 'Never Miss Bus recording',
        messageNotification: 'Screen recording is in progress',
      );
      if (!mounted) return;
      setState(() => _recording = started);
      if (!started) {
        _message('Recording permission नहीं मिली.', error: true);
      } else {
        _message('Recording शुरू है. काम पूरा होने पर Stop दबाएं.');
      }
    } catch (e) {
      _message('Recording start failed: $e', error: true);
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    setState(() => _working = true);
    try {
      final String path = await FlutterScreenRecording.stopRecordScreen;
      CaptureService.lastRecordingPath = path;
      if (!mounted) return;
      setState(() {
        _recording = false;
        _recordingPath = path;
        _working = false;
      });
      _message('Video तैयार है. अब Share Video दबाएं.');
    } catch (e) {
      if (mounted) setState(() => _working = false);
      _message('Recording stop failed: $e', error: true);
    }
  }

  Future<void> _shareRecording() async {
    final String? path = _recordingPath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      _message('पहले screen recording बनाएं.', error: true);
      return;
    }
    await Share.shareXFiles(
      <XFile>[XFile(path)],
      text: 'Never Miss Bus issue recording',
      subject: 'Never Miss Bus screen recording',
    );
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? NmbColors.danger : NmbColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture & Report')),
      body: ResponsiveBody(
        child: ListView(
          children: <Widget>[
            Text('Capture & Report', style: NmbTypography.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Take a screenshot or record the problem so the school team can see exactly what happened.',
              style: NmbTypography.bodySecondary,
            ),
            const SizedBox(height: 16),
            NmbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(children: <Widget>[
                    CircleAvatar(
                      backgroundColor: NmbColors.primarySoft,
                      child: Icon(Icons.screenshot_monitor_rounded,
                          color: NmbColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Screenshot of the current app screen',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (_screenshot != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(_screenshot!, fit: BoxFit.contain),
                    )
                  else
                    Container(
                      height: 130,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: NmbColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('No screenshot captured yet.'),
                    ),
                  const SizedBox(height: 12),
                  Row(children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _working ? null : _captureCurrent,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(_working ? 'Working…' : 'Take Screenshot'),
                      ),
                    ),
                    if (_screenshot != null) ...<Widget>[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Share screenshot',
                        onPressed: _shareScreenshot,
                        icon: const Icon(Icons.share_rounded),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NmbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(children: <Widget>[
                    CircleAvatar(
                      backgroundColor: NmbColors.accentSoft,
                      child: Icon(Icons.videocam_rounded,
                          color: NmbColors.accentDark),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Screen recording',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    if (_recording)
                      const Icon(Icons.fiber_manual_record,
                          color: NmbColors.danger),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Android will ask for screen-capture permission. The recording is saved as an MP4 on this device.',
                    style: NmbTypography.bodySecondary,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _working
                        ? null
                        : (_recording ? _stopRecording : _startRecording),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _recording ? NmbColors.danger : NmbColors.primary,
                    ),
                    icon: Icon(_recording
                        ? Icons.stop_rounded
                        : Icons.fiber_manual_record_rounded),
                    label: Text(_recording
                        ? 'Stop & Save Recording'
                        : 'Start Screen Recording'),
                  ),
                  if (_recordingPath != null) ...<Widget>[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _shareRecording,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share Video'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tip: पहले जिस screen पर problem दिख रही है वहां जाएं, फिर drawer से Capture & Report खोलें. उस screen का screenshot automatically यहां आएगा.',
              style: NmbTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
