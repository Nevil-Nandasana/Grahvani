/// Voice AI Q&A Interface Screen
/// Presents a push-to-talk interface that listens for speech input,
/// sends it to the AI chat endpoint (same RAG pipeline as chat_screen.dart),
/// and speaks the response back using the device TTS.
///
/// Dependencies: speech_to_text ^6.0.0 + flutter_tts ^3.8.5
/// Add to pubspec.yaml before building:
///   speech_to_text: ^6.0.0
///   flutter_tts: ^3.8.5
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Voice State ──────────────────────────────────────────────────────────────

enum VoiceState { idle, listening, processing, speaking, error }

class VoiceQANotifier extends StateNotifier<VoiceState> {
  VoiceQANotifier() : super(VoiceState.idle);

  final List<({String role, String text})> transcript = [];
  String _currentQuestion = '';
  String? _errorMessage;

  String? get errorMessage => _errorMessage;
  String get currentQuestion => _currentQuestion;

  // These would be backed by real packages:
  // import 'package:speech_to_text/speech_to_text.dart';
  // import 'package:flutter_tts/flutter_tts.dart';

  Future<void> startListening() async {
    state = VoiceState.listening;
    _errorMessage = null;
    _currentQuestion = '';
    // Real impl: stt.listen(onResult: (result) { ... })
    // Demo: simulate a 2-second listen then auto-answer
    await Future.delayed(const Duration(seconds: 2));
    if (state == VoiceState.listening) {
      _currentQuestion = _demoQuestions[_demoIdx % _demoQuestions.length];
      _demoIdx++;
      await _submit(_currentQuestion);
    }
  }

  int _demoIdx = 0;
  static const _demoQuestions = [
    'What does my Jupiter placement mean?',
    'When does my current dasha period end?',
    'Is this a good time for major decisions?',
    'What is my moon sign and its significance?',
    'Tell me about Sade Sati and how it affects me.',
  ];

  Future<void> stopListening() async {
    if (state != VoiceState.listening) return;
    // Real impl: stt.stop()
    state = VoiceState.idle;
  }

  Future<void> _submit(String question) async {
    state = VoiceState.processing;
    transcript.add((role: 'user', text: question));

    try {
      // Real impl: POST /api/v1/chat/{sessionId}/message
      await Future.delayed(const Duration(seconds: 2));
      const answer =
          'Based on your natal chart, Jupiter in your 9th house indicates a strong affinity for philosophy, higher learning, and spiritual growth. This placement traditionally bestows wisdom and good fortune in long-distance travel and religious pursuits. Your current Jupiter Antar Dasha amplifies these themes significantly.';

      transcript.add((role: 'assistant', text: answer));
      state = VoiceState.speaking;

      // Real impl: tts.speak(answer)
      await Future.delayed(const Duration(seconds: 4));
      state = VoiceState.idle;
    } catch (e) {
      _errorMessage = e.toString();
      state = VoiceState.error;
    }
  }

  void reset() {
    state = VoiceState.idle;
    _errorMessage = null;
    _currentQuestion = '';
  }

  void clearTranscript() {
    transcript.clear();
    state = VoiceState.idle;
  }
}

final voiceQAProvider =
    StateNotifierProvider.autoDispose<VoiceQANotifier, VoiceState>(
  (_) => VoiceQANotifier(),
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class VoiceQAScreen extends ConsumerWidget {
  const VoiceQAScreen({super.key, required this.chartId});
  final String chartId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceQAProvider);
    final notifier = ref.read(voiceQAProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF080814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080814),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Voice AI',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (notifier.transcript.isNotEmpty)
            TextButton(
              onPressed: () => notifier.clearTranscript(),
              child: const Text('Clear',
                  style: TextStyle(color: Color(0xFF7C6EFA), fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Transcript area
          Expanded(
            child: notifier.transcript.isEmpty
                ? _IdleHint(voiceState: voiceState)
                : _TranscriptView(
                    transcript: notifier.transcript,
                    voiceState: voiceState,
                    currentQuestion: notifier.currentQuestion,
                  ),
          ),

          // Microphone control
          _MicControl(
            state: voiceState,
            onStart: () => notifier.startListening(),
            onStop: () => notifier.stopListening(),
            onReset: () => notifier.reset(),
          ),

          // Info bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                voiceState == VoiceState.idle
                    ? 'Tap the mic and ask anything about your chart'
                    : voiceState == VoiceState.listening
                        ? 'Listening… tap again to stop'
                        : voiceState == VoiceState.processing
                            ? 'Grahvani AI is thinking…'
                            : voiceState == VoiceState.speaking
                                ? 'Speaking response…'
                                : 'Error — tap to retry',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Idle Hint ────────────────────────────────────────────────────────────────

class _IdleHint extends StatelessWidget {
  const _IdleHint({required this.voiceState});
  final VoiceState voiceState;

  static const _suggestions = [
    'What does my Moon sign mean?',
    'When does my current dasha end?',
    'Tell me about my ascendant',
    'Is this a good year for marriage?',
    'Explain my Jupiter placement',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎙️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          const Text(
            'Ask Grahvani anything',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Speak naturally about your birth chart,\ndasha periods, or planetary transits.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF6B6B99), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestions.map((s) => _SuggestionChip(text: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FDB).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5B4FDB).withOpacity(0.3)),
      ),
      child: Text(
        '"$text"',
        style: const TextStyle(color: Color(0xFF9B93CC), fontSize: 12),
      ),
    );
  }
}

// ─── Transcript View ──────────────────────────────────────────────────────────

class _TranscriptView extends StatefulWidget {
  const _TranscriptView({
    required this.transcript,
    required this.voiceState,
    required this.currentQuestion,
  });
  final List<({String role, String text})> transcript;
  final VoiceState voiceState;
  final String currentQuestion;

  @override
  State<_TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<_TranscriptView> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _TranscriptView old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      children: [
        ...widget.transcript.map((m) => _MessageBubble(message: m)),
        if (widget.voiceState == VoiceState.listening &&
            widget.currentQuestion.isNotEmpty)
          _LiveTranscriptBubble(text: widget.currentQuestion),
        if (widget.voiceState == VoiceState.processing)
          const _ThinkingBubble(),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ({String role, String text}) message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF7C6EFA), Color(0xFF3B2FBE)],
                ),
              ),
              child: const Center(
                child: Text('🪐', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF3B2FBE)
                    : const Color(0xFF12122A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFF2A2A4A)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5B4FDB).withOpacity(0.2),
              ),
              child: const Center(
                child: Icon(Icons.mic, color: Color(0xFF7C6EFA), size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveTranscriptBubble extends StatelessWidget {
  const _LiveTranscriptBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B2FBE).withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(color: const Color(0xFF5B4FDB)),
              ),
              child: Text(
                '$text…',
                style: const TextStyle(
                    color: Color(0xFFB0A8FF), fontSize: 13, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF7C6EFA), Color(0xFF3B2FBE)],
              ),
            ),
            child:
                const Center(child: Text('🪐', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Row(
                children: List.generate(3, (i) {
                  final opacity = math.sin(
                          _controller.value * math.pi + i * math.pi / 3)
                      .clamp(0.3, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(
                            124, 110, 250, opacity.toDouble()),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mic Control ──────────────────────────────────────────────────────────────

class _MicControl extends StatefulWidget {
  const _MicControl({
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });
  final VoiceState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  @override
  State<_MicControl> createState() => _MicControlState();
}

class _MicControlState extends State<_MicControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == VoiceState.listening;
    final isBusy = widget.state == VoiceState.processing ||
        widget.state == VoiceState.speaking;
    final isError = widget.state == VoiceState.error;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) {
          return Transform.scale(
            scale: isListening ? _pulseAnim.value : 1.0,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: isError
              ? widget.onReset
              : isBusy
                  ? null
                  : isListening
                      ? widget.onStop
                      : widget.onStart,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isListening
                    ? [const Color(0xFFFF6B6B), const Color(0xFFFF4444)]
                    : isBusy
                        ? [const Color(0xFF3B2FBE), const Color(0xFF1A1235)]
                        : isError
                            ? [Colors.redAccent, Colors.red]
                            : [
                                const Color(0xFF7C6EFA),
                                const Color(0xFF3B2FBE)
                              ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF5B4FDB))
                      .withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: isBusy
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white54,
                      ),
                    )
                  : Icon(
                      isListening
                          ? Icons.stop_rounded
                          : isError
                              ? Icons.refresh
                              : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
