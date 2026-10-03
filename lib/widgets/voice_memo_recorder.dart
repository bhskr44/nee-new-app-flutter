import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Record-once, play-back-and-re-record voice memo picker. Reports the local
/// file path of the recording via [onChanged] (null once cleared/re-recording
/// starts) — the caller uploads that file path on submit.
class VoiceMemoRecorder extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  const VoiceMemoRecorder({super.key, required this.onChanged});

  @override
  State<VoiceMemoRecorder> createState() => _VoiceMemoRecorderState();
}

class _VoiceMemoRecorderState extends State<VoiceMemoRecorder> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _recording = false;
  bool _playing = false;
  String? _path;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  StreamSubscription<void>? _playerCompleteSub;

  @override
  void initState() {
    super.initState();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _playerCompleteSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is needed to record a voice memo.')),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/estimate_voice_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    _elapsed = Duration.zero;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    setState(() {
      _recording = true;
      _path = null;
    });
    widget.onChanged(null);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _ticker?.cancel();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _path = path;
    });
    widget.onChanged(path);
  }

  Future<void> _togglePlayback() async {
    if (_path == null) return;
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _player.play(DeviceFileSource(_path!));
    if (mounted) setState(() => _playing = true);
  }

  void _discard() {
    final path = _path;
    setState(() {
      _path = null;
      _elapsed = Duration.zero;
    });
    widget.onChanged(null);
    if (path != null) {
      File(path).delete().ignore();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_path != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD8CEEF)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _togglePlayback,
              icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: const Color(0xFF6A1B9A), size: 32),
            ),
            Expanded(
              child: Text('Voice memo — ${_fmt(_elapsed)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: _discard,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _recording ? _stopRecording : _startRecording,
            icon: Icon(_recording ? Icons.stop_circle_outlined : Icons.mic_none_outlined,
                color: _recording ? Colors.red : const Color(0xFF6A1B9A)),
            label: Text(
              _recording ? 'Stop (${_fmt(_elapsed)})' : 'Record a voice memo (optional)',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _recording ? Colors.red : const Color(0xFF6A1B9A),
              side: BorderSide(color: _recording ? Colors.red : const Color(0xFF6A1B9A)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
