enum ChatRole { user, thuta, system }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.sentAt,
  });

  final ChatRole role;
  final String text;
  final DateTime sentAt;
}
