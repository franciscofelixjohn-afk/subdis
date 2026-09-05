import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? bookingId;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.bookingId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? chatId;
  bool isSending = false;
  bool isCheckingBooking = true;
  bool isBookingAccepted = false;
  late String resolvedOtherUserName;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    resolvedOtherUserName = widget.otherUserName;
    _verifyBookingAndInitChat();
  }

  Future<void> _verifyBookingAndInitChat() async {
    try {
      if (widget.otherUserId.isNotEmpty) {
        String fetchedName = '';
        try {
          final providerDoc = await FirebaseFirestore.instance
              .collection('providers')
              .doc(widget.otherUserId)
              .get();

          if (providerDoc.exists && providerDoc.data() != null) {
            final data = providerDoc.data()!;
            fetchedName = data['name'] ?? data['fullName'] ?? '';
          }

          if (fetchedName.isEmpty || fetchedName == 'User') {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.otherUserId)
                .get();

            if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data()!;
              fetchedName = data['fullName'] ?? data['name'] ?? '';
            }
          }
        } catch (e) {
          // Ignore error
        }

        if (fetchedName.isNotEmpty && fetchedName != 'User') {
          resolvedOtherUserName = fetchedName;
        }
      }

      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        final bookingDoc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .get();

        if (bookingDoc.exists) {
          final data = bookingDoc.data();
          final status = (data?['status'] ?? '').toString().toLowerCase();
          if (status == 'accepted') {
            isBookingAccepted = true;
          }
        }
      } else {
        isBookingAccepted = true;
      }

      if (!isBookingAccepted) {
        setState(() {
          isCheckingBooking = false;
        });
        return;
      }

      final id = await _chatService.createOrGetChat(
        currentUserId: currentUserId,
        otherUserId: widget.otherUserId,
        bookingId: widget.bookingId,
        currentUserName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
        otherUserName: resolvedOtherUserName,
      );

      if (!mounted) return;

      setState(() {
        chatId = id;
        isCheckingBooking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCheckingBooking = false;
      });

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to open chat'),
        ),
      );
    }
  }

  void _scrollToLatestMessage() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (chatId == null || text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await _chatService.sendMessage(
        chatId: chatId!,
        senderId: currentUserId,
        text: text,
      );

      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLatestMessage();
      });
    } catch (e) {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingBooking) {
      return Scaffold(
        backgroundColor: const Color(0xFF020408),
        appBar: AppBar(
          backgroundColor: const Color(0xFF061021),
          foregroundColor: Colors.white,
          title: Text(resolvedOtherUserName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    if (!isBookingAccepted) {
      return Scaffold(
        backgroundColor: const Color(0xFF020408),
        appBar: AppBar(
          backgroundColor: const Color(0xFF061021),
          foregroundColor: Colors.white,
          title: Text(resolvedOtherUserName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 48, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                Text(
                  'Chat Restricted',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Messaging is only available once the booking request has been officially accepted.',
                  style:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (chatId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF020408),
        appBar: AppBar(
          backgroundColor: const Color(0xFF061021),
          foregroundColor: Colors.white,
          title: Text(resolvedOtherUserName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061021),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          resolvedOtherUserName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(chatId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading messages',
                        style: TextStyle(color: Colors.white54)),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                  );
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToLatestMessage();
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return ChatMessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              color: const Color(0xFF061021),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF38BDF8), width: 1.2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: isSending ? null : _sendMessage,
                      icon: isSending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}