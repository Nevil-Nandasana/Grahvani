/// Chat Domain — Riverpod Notifier managing SSE streaming chat state
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import 'chat_model.dart';

class ChatState {
  const ChatState({
    required this.messages,
    required this.isStreaming,
    this.sessionId,
    this.errorMessage,
    this.quotaExhausted = false,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? sessionId;
  final String? errorMessage;
  final bool quotaExhausted;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? sessionId,
    String? errorMessage,
    bool? quotaExhausted,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage,
      quotaExhausted: quotaExhausted ?? this.quotaExhausted,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this.chartId, this._repository)
      : super(const ChatState(messages: [], isStreaming: false));

  final String chartId;
  final ChatRepository _repository;

  Future<void> initSession() async {
    if (state.sessionId != null) return;
    try {
      final sessionId = await _repository.createSession(chartId);
      state = state.copyWith(sessionId: sessionId);
      await _loadHistory(sessionId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> _loadHistory(String sessionId) async {
    try {
      final messages = await _repository.loadMessages(sessionId);
      state = state.copyWith(messages: messages);
    } catch (_) {}
  }

  Future<void> sendMessage(String promptText) async {
    final sessionId = state.sessionId;
    if (sessionId == null || promptText.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: promptText,
      createdAt: DateTime.now(),
    );

    final assistantMsgPlaceholder = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: ChatRole.assistant,
      content: '',
      isStreaming: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsgPlaceholder],
      isStreaming: true,
      errorMessage: null,
    );

    var currentContent = '';
    var currentCitations = <CitationRef>[];

    try {
      await for (final event in _repository.streamChat(
        sessionId: sessionId,
        prompt: promptText,
      )) {
        switch (event) {
          case SseDeltaEvent(:final content):
            currentContent += content;
            _updateLastAssistantMessage(
              content: currentContent,
              isStreaming: true,
              citations: currentCitations,
            );
          case SseCitationsEvent(:final citations):
            currentCitations = citations;
            _updateLastAssistantMessage(
              content: currentContent,
              isStreaming: true,
              citations: currentCitations,
            );
          case SseDoneEvent(:final totalTokens):
            _updateLastAssistantMessage(
              content: currentContent,
              isStreaming: false,
              citations: currentCitations,
              tokensUsed: totalTokens,
            );
            state = state.copyWith(isStreaming: false);
          case SseErrorEvent(:final code, :final message):
            final isQuota = code == 'RATE_LIMIT_EXCEEDED' || code == 'QUOTA_EXHAUSTED';
            state = state.copyWith(
              isStreaming: false,
              errorMessage: message,
              quotaExhausted: isQuota,
            );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        errorMessage: e.toString(),
      );
    }
  }

  void _updateLastAssistantMessage({
    required String content,
    required bool isStreaming,
    required List<CitationRef> citations,
    int? tokensUsed,
  }) {
    final msgs = List<ChatMessage>.from(state.messages);
    if (msgs.isEmpty) return;

    final lastIdx = msgs.length - 1;
    if (msgs[lastIdx].role == ChatRole.assistant) {
      msgs[lastIdx] = msgs[lastIdx].copyWith(
        content: content,
        isStreaming: isStreaming,
        citations: citations,
        tokensUsed: tokensUsed,
      );
    }

    state = state.copyWith(messages: msgs);
  }
}

final chatNotifierProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, chartId) => ChatNotifier(chartId, ref.watch(chatRepositoryProvider)),
);
