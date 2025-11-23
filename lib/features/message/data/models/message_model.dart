import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel(String text) : super(text);

  // Keep the generic fromJson that expects { "message": "..." }
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Prefer 'message', fall back to 'title' or 'content'
    final message = json['message'] as String? ??
                    json['title'] as String? ??
                    json['content'] as String? ??
                    '';
    return MessageModel(message);
  }

  // New factory to parse the quotable API: { "content": "...", ... }
  factory MessageModel.fromQuotableApi(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    return MessageModel(content);
  }

  Map<String, dynamic> toJson() {
    return {'message': text};
  }
}
