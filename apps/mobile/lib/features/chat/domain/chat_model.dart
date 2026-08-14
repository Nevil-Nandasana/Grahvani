/// Chat Domain Models
library;

import 'package:flutter/foundation.dart';

enum ChatRole { user, assistant }

@immutable
class CitationRef {
  const CitationRef({
    required this.refId,
    required this.label,
    required this.sourceTitle,
    required this.chapter,
    required this.slokaNumber,
    required this.content,
  });

  final String refId;
  final String label;
  final String sourceTitle;
  final String? chapter;
  final String? slokaNumber;
  final String content;

  factory CitationRef.fromJson(Map<String, dynamic> json) {
    return CitationRef(
      refId: json['ref_id'] as String,
      label: json['label'] as String,
      sourceTitle: json['source_title'] as String,
      chapter: json['chapter'] as String?,
      slokaNumber: json['sloka_number'] as String?,
      content: json['content'] as String,
    );
  }
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    this.isStreaming = false,
    this.tokensUsed,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String content;
  final List<CitationRef> citations;
  final bool isStreaming;
  final int? tokensUsed;
  final DateTime createdAt;

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    List<CitationRef>? citations,
    int? tokensUsed,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      isStreaming: isStreaming ?? this.isStreaming,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      createdAt: createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['message_id'] as String,
      role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
      content: json['content'] as String,
      citations: ((json['citations'] as List<dynamic>?) ?? [])
          .map((e) => CitationRef.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tokensUsed: json['tokens_used'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
