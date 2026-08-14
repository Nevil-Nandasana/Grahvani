/// Chat Screen — SSE streaming AI interpretation UI with citation chips
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_model.dart';
import '../domain/chat_provider.dart';
import '../../profile/domain/profile_provider.dart';
import '../../profile/domain/profile_model.dart';
import '../../subscriptions/presentation/paywall_sheet.dart';
import '../../theme/app_colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chartId});
  final String chartId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();
  late String _activeChartId;
  String _activeProfileName = '';
  int _charCount = 0;

  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _activeChartId = widget.chartId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profiles = ref.read(profilesNotifierProvider).valueOrNull ?? [];
      if (profiles.isNotEmpty) {
        final current = profiles.firstWhere(
          (p) => p.id == _activeChartId,
          orElse: () => profiles.first,
        );
        _activeProfileName = current.name;
        _activeChartId = current.id;
      }
      ref.read(chatNotifierProvider(_activeChartId).notifier).initSession(
            profileName: _activeProfileName,
          );
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? directText]) async {
    final text = (directText ?? _promptController.text).trim();
    if (text.isEmpty) return;
    _promptController.clear();
    setState(() => _charCount = 0);

    // Slash command handling: /clear
    if (text.toLowerCase() == '/clear') {
      ref
          .read(chatNotifierProvider(_activeChartId).notifier)
          .clearChat(profileName: _activeProfileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat display cleared.'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF2A1B38),
          ),
        );
      }
      return;
    }

    // Slash command handling: /reset
    if (text.toLowerCase() == '/reset') {
      ref
          .read(chatNotifierProvider(_activeChartId).notifier)
          .resetSession(profileName: _activeProfileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat session reset. Fresh reading initialized.'),
            duration: Duration(seconds: 1),
            backgroundColor: AppColors.primaryBurgundy,
          ),
        );
      }
      return;
    }

    await ref
        .read(chatNotifierProvider(_activeChartId).notifier)
        .sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(_activeChartId));
    final profilesAsync = ref.watch(profilesNotifierProvider);
    final profiles = profilesAsync.valueOrNull ?? [];

    // Sync profile name if available
    if (profiles.isNotEmpty) {
      final matched = profiles.firstWhere(
        (p) => p.id == _activeChartId,
        orElse: () => profiles.first,
      );
      if (_activeProfileName != matched.name) {
        _activeProfileName = matched.name;
      }
    }

    // Scroll when new messages arrive
    ref.listen(chatNotifierProvider(_activeChartId), (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0713),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0B1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: _buildProfileSelector(profiles),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.gold),
            color: const Color(0xFF1B1128),
            onSelected: (val) {
              if (val == 'clear') {
                _sendMessage('/clear');
              } else if (val == 'reset') {
                _sendMessage('/reset');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Clear Screen (/clear)', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, color: AppColors.gold, size: 18),
                    SizedBox(width: 8),
                    Text('Reset Session (/reset)', style: TextStyle(color: AppColors.gold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quota exhausted banner
          if (chatState.quotaExhausted) _buildQuotaBanner(context),

          // Messages list
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, i) {
                      final msg = chatState.messages[i];
                      return _ChatBubble(message: msg);
                    },
                  ),
          ),

          // Input bar
          _buildInputBar(context, chatState.isStreaming, chatState.quotaExhausted),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(List<BirthProfile> profiles) {
    if (profiles.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grahvani AI',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Grounded Vedic Interpretation',
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 11)),
        ],
      );
    }

    final selectedId = profiles.any((p) => p.id == _activeChartId)
        ? _activeChartId
        : profiles.first.id;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedId,
        dropdownColor: const Color(0xFF1B1128),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gold, size: 20),
        items: profiles.map((p) {
          return DropdownMenuItem<String>(
            value: p.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      p.placeName.isNotEmpty ? p.placeName : 'Birth Profile',
                      style: const TextStyle(color: AppColors.gold, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (newId) {
          if (newId != null && newId != _activeChartId) {
            final target = profiles.firstWhere((p) => p.id == newId, orElse: () => profiles.first);
            setState(() {
              _activeChartId = newId;
              _activeProfileName = target.name;
            });
            ref
                .read(chatNotifierProvider(newId).notifier)
                .initSession(profileName: target.name);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✨', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text(
              'Ask Grahvani',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ask about your planetary placements,\ndasha periods, or karmic patterns.\nAll answers are grounded in classical Vedic texts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF2A1A3A),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFFB09EFF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Daily free limit reached. Upgrade to Premium for 100 daily interpretations.",
              style: const TextStyle(
                  color: Color(0xFFB09EFF), fontSize: 12, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: () => PaywallSheet.show(context),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Upgrade',
                style: TextStyle(
                    color: AppColors.primaryBurgundy,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isStreaming, bool quotaExhausted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0A18),
        border: Border(top: BorderSide(color: Color(0xFF261938))),
      ),
      child: Column(
        children: [
          // Quick shortcut chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _buildQuickChip('/clear', Icons.cleaning_services_outlined, () => _sendMessage('/clear')),
                const SizedBox(width: 6),
                _buildQuickChip('/reset', Icons.restart_alt, () => _sendMessage('/reset')),
                const SizedBox(width: 6),
                _buildQuickChip('💼 Career Guidance', null, () => _sendMessage('What does my chart say about my career and success?')),
                const SizedBox(width: 6),
                _buildQuickChip('🪐 Current Dasha', null, () => _sendMessage('Which planetary dasha is active and what are its effects?')),
                const SizedBox(width: 6),
                _buildQuickChip('❤️ Relationships', null, () => _sendMessage('Can you analyze my 7th house and relationship prospects?')),
                const SizedBox(width: 6),
                _buildQuickChip('🌿 Remedies', null, () => _sendMessage('What Vedic remedies and mantras are recommended for my chart?')),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: _maxChars,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  enabled: !isStreaming && !quotaExhausted,
                  onChanged: (v) => setState(() => _charCount = v.length),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: quotaExhausted
                        ? 'Daily limit reached...'
                        : 'Ask about planets, yogas, or type /clear...',
                    hintStyle: const TextStyle(color: Color(0xFF5A4A7A)),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF161026),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E2042)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E2042)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                key: const Key('chat_send_button'),
                onTap: isStreaming || quotaExhausted ? null : () => _sendMessage(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isStreaming || quotaExhausted)
                        ? const Color(0xFF2A1C38)
                        : AppColors.primaryBurgundy,
                    boxShadow: (isStreaming || quotaExhausted)
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primaryBurgundy.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ],
                  ),
                  child: Center(
                    child: isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Type /clear or /reset anytime',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B5885),
                ),
              ),
              Text(
                '$_charCount/$_maxChars',
                style: TextStyle(
                  fontSize: 10,
                  color: _charCount > 450
                      ? Colors.orangeAccent
                      : const Color(0xFF6B5885),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, IconData? icon, VoidCallback onTap) {
    final isCommand = label.startsWith('/');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isCommand ? const Color(0xFF261536) : const Color(0xFF181026),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCommand ? AppColors.gold.withOpacity(0.5) : const Color(0xFF2E2042),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isCommand ? AppColors.gold : Colors.white70),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isCommand ? AppColors.gold : Colors.white70,
                fontSize: 11,
                fontWeight: isCommand ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Bubble ───────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!_isUser) _buildAvatar(),
          if (!_isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: _isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _isUser
                        ? AppColors.primaryBurgundy
                        : AppColors.darkBgElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: _isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: _isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: _isUser
                        ? null
                        : Border.all(color: AppColors.darkBgSecondary),
                  ),
                  child: _isUser
                      ? Text(message.content,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, height: 1.5))
                      : _buildAssistantContent(context),
                ),
                // Citation chips
                if (!_isUser && message.citations.isNotEmpty)
                  _buildCitationChips(context),
              ],
            ),
          ),
          if (_isUser) const SizedBox(width: 8),
          if (_isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAssistantContent(BuildContext context) {
    if (message.isStreaming && message.content.isEmpty) {
      return const _TypingIndicator();
    }
    return _buildFormattedText(context, message.content);
  }

  Widget _buildFormattedText(BuildContext context, String text) {
    return SelectableText(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }

  Widget _buildCitationChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: message.citations
            .map((c) => _CitationChip(citation: c))
            .toList(),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [AppColors.primaryBurgundy, AppColors.primaryBurgundyDark],
        ),
      ),
      child: const Center(
        child: Text('🪐', style: TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkBgSecondary,
      ),
      child: const Icon(Icons.person, color: Colors.white54, size: 16),
    );
  }
}

// ─── Citation Chip ─────────────────────────────────────────────────────────

class _CitationChip extends StatelessWidget {
  const _CitationChip({required this.citation});
  final CitationRef citation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCitationModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryBurgundy.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: AppColors.primaryBurgundy.withOpacity(0.4), width: 0.8),
        ),
        child: Text(
          '[${citation.refId}] ${citation.sourceTitle}',
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showCitationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBgElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBgStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBurgundy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryBurgundy.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      citation.sourceTitle,
                      style: const TextStyle(
                          color: AppColors.primaryBurgundy,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    if (citation.chapter != null || citation.slokaNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          [
                            if (citation.chapter != null)
                              citation.chapter!,
                            if (citation.slokaNumber != null)
                              'Śloka ${citation.slokaNumber}',
                          ].join(' • '),
                          style: const TextStyle(
                              color: AppColors.textSecondaryDark, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Source Text',
                  style: TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkBgSecondary),
                ),
                child: SelectableText(
                  citation.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.7,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Typing Indicator ──────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (_, __) {
            final delay = i * 0.2;
            final opacity = ((math.sin(_animation.value * 3.14 - delay) + 1) / 2)
                .clamp(0.2, 1.0);
            return Opacity(
              opacity: opacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBurgundy,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
