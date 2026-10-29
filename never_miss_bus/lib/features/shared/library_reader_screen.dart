import 'dart:convert';

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
  WebViewController? _webView;
  AudioPlayer? _audio;
  String? _error;
  bool _audioLoading = false;

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
    if (_audio == null) return;
    setState(() => _audioLoading = true);
    try {
      final List<String> urls =
          widget.audioUrls.isNotEmpty ? widget.audioUrls : <String>[widget.url];
      if (urls.length > 1) {
        await _audio!.setAudioSource(
          ConcatenatingAudioSource(
            children: urls
                .map((String value) => AudioSource.uri(Uri.parse(value)))
                .toList(growable: false),
          ),
        );
      } else {
        await _audio!.setUrl(urls.first);
      }
      if (mounted) setState(() => _audioLoading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _audioLoading = false;
          _error =
              'Audio could not load. Please check your internet connection.\n$error';
        });
      }
    }
  }

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          )
        : widget.isAudio
            ? _AudioPlayerView(player: _audio!, loading: _audioLoading)
            : _isPlainText
                ? _TextReader(url: widget.url)
                : WebViewWidget(controller: _webView!);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }
}

class _AudioPlayerView extends StatelessWidget {
  const _AudioPlayerView({required this.player, required this.loading});
  final AudioPlayer player;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
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
                          onChanged: duration == Duration.zero
                              ? null
                              : (double value) => player.seek(
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

class _TextReader extends StatefulWidget {
  const _TextReader({required this.url});
  final String url;

  @override
  State<_TextReader> createState() => _TextReaderState();
}

class _TextReaderState extends State<_TextReader> {
  late final Future<String> _englishFuture;
  String? _hindiText;
  bool _hindi = false;
  bool _translating = false;
  String? _translationError;

  @override
  void initState() {
    super.initState();
    _englishFuture = _load();
  }

  Future<String> _load() async {
    final http.Response response = await http.get(
      Uri.parse(widget.url),
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

  Future<void> _translate(String english) async {
    if (_hindiText != null) {
      setState(() => _hindi = true);
      return;
    }
    setState(() {
      _translating = true;
      _translationError = null;
    });
    try {
      // Translate in small chunks so long books do not exceed the request limit.
      final List<String> chunks = <String>[];
      for (int i = 0; i < english.length; i += 1800) {
        chunks.add(english.substring(i, (i + 1800).clamp(0, english.length)));
      }
      final StringBuffer result = StringBuffer();
      for (final String chunk in chunks) {
        final Uri uri = Uri.https(
            'translate.googleapis.com', '/translate_a/single', <String, String>{
          'client': 'gtx',
          'sl': 'en',
          'tl': 'hi',
          'dt': 't',
          'q': chunk,
        });
        final http.Response response = await http.get(uri);
        if (response.statusCode != 200) {
          throw Exception(
              'Translation service returned ${response.statusCode}.');
        }
        final dynamic data = jsonDecode(response.body);
        final List<dynamic> parts = data is List && data.isNotEmpty
            ? (data[0] as List<dynamic>? ?? <dynamic>[])
            : <dynamic>[];
        result.write(parts
            .whereType<List<dynamic>>()
            .map((List<dynamic> part) => part.isNotEmpty ? '${part[0]}' : '')
            .join());
      }
      if (!mounted) return;
      setState(() {
        _hindiText = result.toString();
        _hindi = true;
        _translating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _translating = false;
        _translationError = 'Hindi translation could not load.\n$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: _englishFuture,
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
          final String english = snapshot.data ?? '';
          final String text = _hindi ? (_hindiText ?? '') : english;
          return Column(
            children: <Widget>[
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      const Text('Read in:',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('English'),
                        selected: !_hindi,
                        onSelected: (_) => setState(() => _hindi = false),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('हिंदी'),
                        selected: _hindi,
                        onSelected:
                            _translating ? null : (_) => _translate(english),
                      ),
                      if (_translating) ...<Widget>[
                        const SizedBox(width: 10),
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ],
                  ),
                ),
              ),
              if (_translationError != null)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(_translationError!, textAlign: TextAlign.center),
                ),
              Expanded(
                child: SelectionArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                    child: Text(text,
                        style: const TextStyle(fontSize: 16, height: 1.55)),
                  ),
                ),
              ),
            ],
          );
        },
      );
}
