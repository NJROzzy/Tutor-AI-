import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/auth_service.dart';
import '../services/tutor_tts_service.dart';
import '../voice/whisper_engine_io.dart';

class TutorChatPage extends StatefulWidget {
  final String subject; // 'math' or 'english'

  const TutorChatPage({super.key, required this.subject});

  @override
  State<TutorChatPage> createState() => _TutorChatPageState();
}

class _TutorChatPageState extends State<TutorChatPage> {
  final _input = TextEditingController();
  final List<_Message> _messages = [];

  bool _sending = false;
  bool _speaking = false;

  // TTS player
  final AudioPlayer _player = AudioPlayer();
  String? _lastAssistantMessage;

  // Whisper / mic
  late final WhisperEngine _whisper;
  bool _initializingWhisper = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _whisper = WhisperEngine();
    _initWhisper();
  }

  Future<void> _initWhisper() async {
    setState(() => _initializingWhisper = true);
    try {
      await _whisper.init();
      // print handled inside engine
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mic init failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _initializingWhisper = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _player.dispose();
    _whisper.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    final child = authService.selectedChild;
    if (child == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No child selected. Go back and pick one.'),
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(_Message(role: 'user', text: text));
      _input.clear();
    });

    try {
      final reply = await authService.tutorChat(
        childId: child.id,
        subject: widget.subject,
        message: text,
      );

      setState(() {
        _lastAssistantMessage = reply;
        _messages.add(_Message(role: 'assistant', text: reply));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _speakLastReply() async {
    final text = _lastAssistantMessage;
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reply to speak yet')),
      );
      return;
    }

    setState(() => _speaking = true);

    try {
      final String path = await tutorTtsService.synthesizeToFile(text);

      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  /// 🎙 Mic button handler
  ///
  /// First tap  -> startRecording()
  /// Second tap -> stopAndTranscribe(), put text in box, auto-send
  Future<void> _onMicPressed() async {
    if (_initializingWhisper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mic is still initializing...')),
      );
      return;
    }

    if (!_whisper.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mic engine not ready')),
      );
      return;
    }

    if (!_listening) {
      // Start recording
      try {
        await _whisper.startRecording();
        setState(() => _listening = true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    } else {
      // Stop recording + transcribe
      setState(() => _listening = false);

      String transcript;
      try {
        transcript = await _whisper.stopAndTranscribe();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcription error: $e')),
        );
        return;
      }

      final cleaned = transcript.trim();
      if (cleaned.isEmpty ||
          cleaned.startsWith('Transcription error') ||
          cleaned.startsWith('(No audio')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(cleaned.isEmpty ? 'No speech detected' : cleaned)),
        );
        return;
      }

      // Put text into input and auto-send
      setState(() {
        _input.text = cleaned;
      });
      await _send();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = authService.selectedChild;
    final isMath = widget.subject.toLowerCase() == 'math';

    final title = isMath ? 'Math Buddy' : 'English Buddy';
    final subtitle = child == null ? '' : 'for ${child.name}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Read last reply',
            onPressed: (_lastAssistantMessage == null || _speaking)
                ? null
                : _speakLastReply,
            icon: _speaking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.volume_up),
          ),
          IconButton(
            tooltip: 'Change subject',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.go('/kid/subject'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[_messages.length - 1 - index];
                  final isUser = msg.role == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.blueAccent.withOpacity(0.8)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input + MIC + Send
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isMath
                            ? 'Ask a math question...'
                            : 'Ask about words, stories...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 🎙 Mic button
                  IconButton(
                    tooltip: _listening ? 'Tap to stop' : 'Tap to speak',
                    onPressed: (_sending || _initializingWhisper)
                        ? null
                        : _onMicPressed,
                    icon: Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      color: _listening ? Colors.redAccent : null,
                    ),
                  ),

                  // 📩 Send button
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String role; // 'user' or 'assistant'
  final String text;

  _Message({required this.role, required this.text});
}
