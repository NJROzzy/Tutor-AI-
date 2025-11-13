import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/tutor_scaffold.dart';
import '../../voice/whisper_engine.dart';

class MathModulesPage extends StatefulWidget {
  const MathModulesPage({super.key});

  @override
  State<MathModulesPage> createState() => _MathModulesPageState();
}

class _MathModulesPageState extends State<MathModulesPage> {
  final _engine = WhisperEngine();
  bool _listening = false;
  bool _ready = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _engine.init().then((_) {
      setState(() => _ready = true);
    }).catchError((e) {
      setState(() => _ready = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Whisper init failed: $e")),
      );
    });
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modules = const ['counting', 'addition'];

    return TutorScaffold(
      title: 'Math Modules',
      body: Column(
        children: [
          // MAIN PAGE CONTENT
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) => ListTile(
                title: Text(modules[i].toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/child/lesson?subject=math&module=${modules[i]}',
                ),
              ),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: modules.length,
            ),
          ),

          const Divider(height: 1),

          // ======== BOTTOM MIC AREA ========
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ----- RESULT ABOVE MIC -----
                if (_result.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                // ----- MIC BUTTON CENTERED -----
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 32,
                      icon: Icon(
                        _listening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        if (!_engine.isReady) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Model still loading…'),
                            ),
                          );
                          return;
                        }

                        try {
                          if (_listening) {
                            setState(() => _listening = false);
                            final text = await _engine.stopAndTranscribe();
                            setState(() => _result = text);
                          } else {
                            setState(() => _result = '');
                            setState(() => _listening = true);
                            await _engine.startRecording();
                          }
                        } catch (e) {
                          setState(() => _listening = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$e")),
                          );
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ----- TEXT BELOW MIC -----
                Text(
                  !_ready
                      ? 'Loading model…'
                      : (_listening ? 'Listening…' : 'Tap mic to speak'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
