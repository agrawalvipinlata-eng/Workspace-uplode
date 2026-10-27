import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LibraryReaderScreen extends StatefulWidget {
  const LibraryReaderScreen({
    super.key,
    required this.title,
    required this.url,
    required this.isAudio,
    this.audioUrls = const <String>[],
  });

  final String title;
  final String url;
  final bool isAudio;
  final List<String> audioUrls;

  @override
  State<LibraryReaderScreen> createState() => _LibraryReaderScreenState();
}

class _LibraryReaderScreenState extends State<LibraryReaderScreen> {
  late final WebViewController _webView;
  AudioPlayer? _audio;
  String? _error;

  bool get _isPlainText =>
      widget.url.toLowerCase().split('?').first.endsWith('.txt');

  @override
  void initState() {
    super.initState();
    if (widget.isAudio) {
      _audio = AudioPlayer();
      _loadAudio();
    } else if (!_isPlainText) {
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
      if (widget.audioUrls.length > 1) {
        await _audio!.setAudioSource(
          ConcatenatingAudioSource(
            children: widget.audioUrls
                .map((String value) => AudioSource.uri(Uri.parse(value)))
                .toList(growable: false),
          ),
        );
      } else {
        await _audio!.setUrl(
            widget.audioUrls.isEmpty ? widget.url : widget.audioUrls.first);
      }
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
              : _isPlainText
                  ? _TextReader(url: widget.url)
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

class _TextReader extends StatelessWidget {
  const _TextReader({required this.url});

  final String url;

  Future<String> _load() async {
    final http.Response response = await http.get(
      Uri.parse(url),
      headers: const <String, String>{
        'Accept': 'text/plain',
        'User-Agent': 'NeverMissBusLibrary/1.0',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Book text server returned ${response.statusCode}.');
    }
    return response.body;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _load(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Book text could not load. Please check your internet connection.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
            child: Text(
              snapshot.data ?? '',
              style: const TextStyle(fontSize: 16, height: 1.55),
            ),
          ),
        );
      },
    );
  }
}
