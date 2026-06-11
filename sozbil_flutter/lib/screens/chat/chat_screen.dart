import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../providers/app_providers.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _chatProvider = StateNotifierProvider<_ChatNotifier, _ChatState>((ref) {
  final api = ref.read(apiServiceProvider);
  return _ChatNotifier(api);
});

class _ChatState {
  final List<ChatMessageModel> messages;
  final bool loading;
  final bool sending;
  final String? error;

  const _ChatState({
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.error,
  });

  _ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? loading,
    bool? sending,
    String? error,
  }) =>
      _ChatState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        error: error,
      );
}

class _ChatNotifier extends StateNotifier<_ChatState> {
  final ApiService _api;
  Timer? _pollTimer;

  _ChatNotifier(this._api) : super(const _ChatState()) {
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _load() async {
    state = state.copyWith(loading: true);
    try {
      final msgs = await _api.getChatMessages();
      state = state.copyWith(messages: msgs, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Ýüklenip bilinmedi');
    }
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final msgs = await _api.getChatMessages();
      if (!mounted) return;
      state = state.copyWith(messages: msgs);
    } catch (_) {}
  }

  Future<void> send(String playerUuid, String message) async {
    if (message.trim().isEmpty) return;
    state = state.copyWith(sending: true, error: null);
    try {
      await _api.sendChatMessage(playerUuid: playerUuid, message: message.trim());
      final msgs = await _api.getChatMessages();
      state = state.copyWith(messages: msgs, sending: false);
    } catch (e) {
      state = state.copyWith(sending: false, error: 'Iberilmedi. Täzeden synany!');
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _shouldAutoScroll = true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final player = ref.read(playerProvider).value;
    if (player == null) return;

    _controller.clear();
    _shouldAutoScroll = true;
    await ref.read(_chatProvider.notifier).send(player.uuid, text);
    // Scroll after messages update
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(_chatProvider);
    final player = ref.watch(playerProvider).value;
    final myUuid = player?.uuid ?? '';

    // Auto-scroll when new messages arrive if user was at bottom
    ref.listen(_chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length && _shouldAutoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Text('💬', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Gürrüňdeşlik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.loading
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? _EmptyChat()
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            final atBottom = _scrollController.position.pixels >=
                                _scrollController.position.maxScrollExtent - 80;
                            _shouldAutoScroll = atBottom;
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, i) {
                            final msg = chatState.messages[i];
                            final isMe = player != null &&
                                msg.displayName == player.displayName;
                            return _MessageBubble(
                              msg: msg,
                              isMe: isMe,
                            );
                          },
                        ),
                      ),
          ),
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.error.withOpacity(0.1),
              child: Text(
                chatState.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          _InputBar(
            controller: _controller,
            sending: chatState.sending,
            enabled: player != null,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💬', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Gürrüňdeşlik boş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ilkinji bolup ýaz!',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  String _timeLabel() {
    final now = DateTime.now();
    final diff = now.difference(msg.createdAt);
    if (diff.inSeconds < 60) return 'Az öň';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} sag';
    return '${msg.createdAt.day}.${msg.createdAt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(emoji: msg.avatarEmoji),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(
                      msg.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 2, right: 2),
                  child: Text(
                    _timeLabel(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            _Avatar(emoji: msg.avatarEmoji),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String emoji;
  const _Avatar({required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      );
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !sending,
                maxLength: 500,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: enabled ? 'Habar ýaz...' : 'Hasaba girmek gerek',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(sending: sending, enabled: enabled, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  const _SendButton({
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: (enabled && !sending) ? onSend : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (enabled && !sending)
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: sending
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      );
}
