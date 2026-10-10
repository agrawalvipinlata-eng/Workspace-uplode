import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/enums.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';

/// SRBS branded 5-second intro shown on every cold app start.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _ready = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/srbs_intro.mp4');
    _controller.addListener(_onVideoUpdate);
    _startIntro();
  }

  Future<void> _startIntro() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      await _controller.play();
      // A safe fallback keeps login usable if a device cannot decode video.
      _fallbackTimer = Timer(const Duration(seconds: 6), _finish);
    } catch (_) {
      _finish();
    }
  }

  void _onVideoUpdate() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.position >= _controller.value.duration &&
        !_controller.value.isPlaying) {
      _finish();
    }
  }

  void _finish() {
    if (!mounted || _navigated) return;
    final AsyncValue<AuthSession?> state = ref.read(sessionProvider);
    if (state.isLoading) {
      Future<void>.delayed(const Duration(milliseconds: 150), _finish);
      return;
    }
    _navigated = true;
    final AuthSession? session = state.valueOrNull;
    final String destination = switch (session?.role) {
      UserRole.student => '/student/home',
      UserRole.driver => '/driver/home',
      UserRole.teacher => '/teacher/class',
      UserRole.admin => '/admin/dashboard',
      null => '/login',
    };
    context.go(destination);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: TextButton(
              onPressed: _finish,
              child: const Text(
                'Skip intro',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
