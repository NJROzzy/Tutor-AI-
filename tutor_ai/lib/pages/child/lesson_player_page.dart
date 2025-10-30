import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tutor_scaffold.dart';

class LessonPlayerPage extends StatefulWidget {
  final String subject; // "math" | "english"
  final String module; // counting | addition | letters | sight_words
  const LessonPlayerPage(
      {super.key, required this.subject, required this.module});

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  late final List<Map<String, dynamic>> _items;
  int _i = 0;
  int _score = 0;
  bool _answered = false;
  String? _chosen;

  @override
  void initState() {
    super.initState();
    _items = _loadItems(widget.subject, widget.module);
  }

  List<Map<String, dynamic>> _loadItems(String subject, String module) {
    // Minimal seed content (5 items each)
    final mathCounting = [
      {
        'q': 'How many apples? 🍎🍎',
        'opts': ['1', '2', '3'],
        'a': '2'
      },
      {
        'q': 'Count the stars ⭐⭐⭐',
        'opts': ['2', '3', '4'],
        'a': '3'
      },
      {
        'q': 'Count the ducks 🦆🦆🦆🦆',
        'opts': ['3', '4', '5'],
        'a': '4'
      },
      {
        'q': 'How many? 🧩🧩',
        'opts': ['1', '2', '3'],
        'a': '2'
      },
      {
        'q': 'Count the cars 🚗🚗🚗',
        'opts': ['2', '3', '4'],
        'a': '3'
      },
    ];
    final mathAddition = [
      {
        'q': '1 + 1 = ?',
        'opts': ['1', '2', '3'],
        'a': '2'
      },
      {
        'q': '2 + 1 = ?',
        'opts': ['2', '3', '4'],
        'a': '3'
      },
      {
        'q': '2 + 2 = ?',
        'opts': ['3', '4', '5'],
        'a': '4'
      },
      {
        'q': '3 + 1 = ?',
        'opts': ['3', '4', '5'],
        'a': '4'
      },
      {
        'q': '5 + 0 = ?',
        'opts': ['4', '5', '6'],
        'a': '5'
      },
    ];
    final engLetters = [
      {
        'q': 'Find the letter',
        'opts': ['A', 'B', 'D'],
        'a': 'B'
      },
      {
        'q': 'Find the letter',
        'opts': ['M', 'N', 'W'],
        'a': 'M'
      },
      {
        'q': 'Find the letter',
        'opts': ['C', 'G', 'Q'],
        'a': 'Q'
      },
      {
        'q': 'Find the letter',
        'opts': ['L', 'I', 'T'],
        'a': 'T'
      },
      {
        'q': 'Find the letter',
        'opts': ['R', 'S', 'T'],
        'a': 'S'
      },
    ];
    final engSight = [
      {
        'q': 'Tap the word “the”',
        'opts': ['to', 'the', 'in'],
        'a': 'the'
      },
      {
        'q': 'Tap the word “and”',
        'opts': ['and', 'an', 'at'],
        'a': 'and'
      },
      {
        'q': 'Tap the word “to”',
        'opts': ['of', 'to', 'do'],
        'a': 'to'
      },
      {
        'q': 'Tap the word “in”',
        'opts': ['on', 'in', 'no'],
        'a': 'in'
      },
      {
        'q': 'Tap the word “of”',
        'opts': ['if', 'of', 'off'],
        'a': 'of'
      },
    ];

    if (subject == 'math' && module == 'counting') return mathCounting;
    if (subject == 'math' && module == 'addition') return mathAddition;
    if (subject == 'english' && module == 'letters') return engLetters;
    if (subject == 'english' && module == 'sight_words') return engSight;
    return mathCounting; // fallback
  }

  void _choose(String opt) {
    if (_answered) return;
    setState(() {
      _chosen = opt;
      _answered = true;
      if (opt == _items[_i]['a']) _score++;
    });
  }

  void _next() {
    if (_i < _items.length - 1) {
      setState(() {
        _i++;
        _answered = false;
        _chosen = null;
      });
    } else {
      context.go('/child/reward', extra: _score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_i];
    final opts = List<String>.from(item['opts'] as List);
    final answer = item['a'] as String;

    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${widget.subject.toUpperCase()} • ${widget.module.toUpperCase()}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['q'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                for (final o in opts) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _choose(o),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _answered
                            ? (o == answer
                                ? Colors.green
                                : (o == _chosen ? Colors.red : null))
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(o, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Text(
                    'Question ${_i + 1} / ${_items.length}   •   Score: $_score',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _answered ? _next : null,
                  child: Text(_i < _items.length - 1 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
