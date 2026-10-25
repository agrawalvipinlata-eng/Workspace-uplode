import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LibraryReaderScreen extends StatefulWidget {
  const LibraryReaderScreen({
    super.key,
    required this.title,
    required this.url,
    required this.isAudio,
  });

  final String title;
  final String url;
  final bool isAudio;

  @override
  State<LibraryReaderScreen> createState() => _LibraryReaderScreenState();
}

class _LibraryReaderScreenState extends State<LibraryReaderScreen> {
  late final WebViewController _webView;
  AudioPlayer? _audio;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isAudio) {
      _audio = AudioPlayer();
      _loadAudio();
    } else {
      _webView = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (WebResourceError error) {
              if (mounted) setState(() => _error = error.description);
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    }
  }

  Future<void> _loadAudio() async {
    try {
      await _audio!.setUrl(widget.url);
    } catch (error) {
      if (mounted) setState(() => _error = 'Audio could not load: $error');
    }
  }

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : widget.isAudio
              ? _AudioPlayerView(player: _audio!)
              : WebViewWidget(controller: _webView),
    );
  }
}

class _AudioPlayerView extends StatelessWidget {
  const _AudioPlayerView({required this.player});
  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.headphones_rounded, size: 72),
                const SizedBox(height: 16),
                const Text('Audio book',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 22),
                StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                    final Duration position = snapshot.data ?? Duration.zero;
                    final Duration duration = player.duration ?? Duration.zero;
                    final double max = duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1;
                    return Column(
                      children: <Widget>[
                        Slider(
                          value:
                              position.inMilliseconds.clamp(0, max).toDouble(),
                          max: max,
                          onChanged: (double value) => player.seek(
                            Duration(milliseconds: value.round()),
                          ),
                        ),
                        Text('${_format(position)} / ${_format(duration)}'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (BuildContext context,
                      AsyncSnapshot<PlayerState> snapshot) {
                    final bool playing = snapshot.data?.playing ?? false;
                    return FilledButton.icon(
                      onPressed: () => playing ? player.pause() : player.play(),
                      icon: Icon(playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded),
                      label: Text(playing ? 'Pause' : 'Play'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _format(Duration value) {
    final String minutes =
        value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours > 0 ? '${value.inHours}:' : ''}$minutes:$seconds';
  }
}
