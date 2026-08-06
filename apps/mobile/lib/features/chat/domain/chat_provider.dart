/// Chat Domain — Riverpod Notifier managing SSE streaming chat state
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/chat_repository.dart';
import 'chat_model.dart';

part 'chat_provider.g.dart';

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

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build(String chartId) {
    return const ChatState(messages: [], isStreaming: false);
  }

  Future<void> initSession() async {
    if (state.sessionId != null) return;
    try {
      final sessionId =
          await ref.read(chatRepositoryProvider).createSession(chartId);
      state = state.copyWith(sessionId: sessionId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> sendMessage(String prompt) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    if (state.isStreaming) return;

    // Optimistically add user message
    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: prompt,
      createdAt: DateTime.now(),
    );

    // Placeholder assistant message (streaming)
    final assistantPlaceholder = ChatMessage(
      id: 'assistant_streaming',
      role: ChatRole.assistant,
      content: '',
      isStreaming: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantPlaceholder],
      isStreaming: true,
      errorMessage: null,
    );

    String accumulatedContent = '';
    List<CitationRef> receivedCitations = [];

    try {
      final stream = ref.read(chatRepositoryProvider).streamChat(
            sessionId: sessionId,
            prompt: prompt,
          );

      await for (final event in stream) {
        if (event is SseDeltaEvent) {
          accumulatedContent += event.content;
          _updateLastAssistantMessage(
            content: accumulatedContent,
            isStreaming: true,
            citations: receivedCitations,
          );
        } else if (event is SseCitationsEvent) {
          receivedCitations = event.citations;
        } else if (event is SseDoneEvent) {
          _updateLastAssistantMessage(
            content: accumulatedContent,
            isStreaming: false,
            citations: receivedCitations,
            tokensUsed: event.totalTokens,
          );
          state = state.copyWith(isStreaming: false);
        } else if (event is SseErrorEvent) {
          final isQuota = event.code == 'ENTITLEMENT_REQUIRED';
          _updateLastAssistantMessage(
            content: event.message,
            isStreaming: false,
            citations: [],
          );
          state = state.copyWith(
            isStreaming: false,
            errorMessage: isQuota ? null : event.message,
            quotaExhausted: isQuota,
          );
          return;
        }
      }
    } catch (e) {
      _updateLastAssistantMessage(
        content: 'An error occurred. Please try again.',
        isStreaming: false,
        citations: [],
      );
      state = state.copyWith(isStreaming: false, errorMessage: e.toString());
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
