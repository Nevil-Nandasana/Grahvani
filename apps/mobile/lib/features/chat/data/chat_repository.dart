/// Chat Data Layer — SSE streaming repository
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../domain/chat_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(dio: ref.watch(apiClientProvider)),
);

class ChatRepository {
  const ChatRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// POST /api/v1/chat/sessions — create a new chat session linked to a chart.
  Future<String> createSession(String chartId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/chat/sessions',
        data: {'chart_id': chartId},
      );
      return response.data!['session_id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/v1/chat/stream — stream grounded Gemini response as SSE.
  /// Yields [SseEvent] objects: delta | citations | done | error
  Stream<SseEvent> streamChat({
    required String sessionId,
    required String prompt,
  }) async* {
    final responseCompleter = Completer<void>();
    final streamController = StreamController<SseEvent>();
    String buffer = '';

    try {
      final response = await _dio.post<ResponseBody>(
        '/api/v1/chat/stream',
        data: {'session_id': sessionId, 'prompt': prompt},
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream;

      stream.listen(
        (bytes) {
          buffer += utf8.decode(bytes);
          final lines = buffer.split('\n');
          buffer = lines.last; // keep incomplete line

          for (final line in lines.take(lines.length - 1)) {
            if (line.startsWith('data: ')) {
              final payload = line.substring(6).trim();
              if (payload.isEmpty) continue;
              try {
                final json = jsonDecode(payload) as Map<String, dynamic>;
                streamController.add(SseEvent.fromJson(json));
              } catch (_) {}
            }
          }
        },
        onDone: () {
          streamController.close();
          if (!responseCompleter.isCompleted) responseCompleter.complete();
        },
        onError: (e) {
          streamController.addError(e);
          if (!responseCompleter.isCompleted) responseCompleter.completeError(e);
        },
      );

      yield* streamController.stream;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /api/v1/chat/sessions/{id}/messages — load message history.
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/chat/sessions/$sessionId/messages',
      );
      final data = response.data ?? [];
      return data
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

// ─── SSE Event Types ──────────────────────────────────────────────────────

abstract class SseEvent {
  factory SseEvent.fromJson(Map<String, dynamic> json) {
    return switch (json['event'] as String?) {
      'delta'     => SseDeltaEvent(content: json['content'] as String),
      'citations' => SseCitationsEvent(
          citations: (json['citations'] as List<dynamic>)
              .map((e) => CitationRef.fromJson(e as Map<String, dynamic>))
              .toList()),
      'done'      => SseDoneEvent(totalTokens: json['total_tokens'] as int?),
      'error'     => SseErrorEvent(
          code: json['code'] as String? ?? 'STREAM_ERROR',
          message: json['message'] as String? ?? 'Unknown error'),
      _           => SseErrorEvent(code: 'UNKNOWN', message: 'Unknown event'),
    };
  }
}

class SseDeltaEvent implements SseEvent {
  final String content;
  const SseDeltaEvent({required this.content});
}

class SseCitationsEvent implements SseEvent {
  final List<CitationRef> citations;
  const SseCitationsEvent({required this.citations});
}

class SseDoneEvent implements SseEvent {
  final int? totalTokens;
  const SseDoneEvent({this.totalTokens});
}

class SseErrorEvent implements SseEvent {
  final String code;
  final String message;
  const SseErrorEvent({required this.code, required this.message});
}
