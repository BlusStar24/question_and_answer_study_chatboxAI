import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../database/models.dart';
import '../database/message_table.dart';
import '../database/box_chat_table.dart';
import '../database/request_table.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  final int receiverId;
  final int boxChatId;
  final UserRole role;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.receiverId,
    required this.boxChatId,
    this.role = UserRole.student,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  final MessageDBHelper _dbHelper = MessageDBHelper();
  final ChatboxDBHelper _chatboxDBHelper = ChatboxDBHelper();
  bool _isLoading = false;
  bool _showEmojiPicker = false;

  final List<String> _emojis = [
    '😊', '👍', '❤️', '😂', '😢', '😍', '🙌', '🔥', '🎉', '😎',
  ];

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadMessages();
  }

  Future<void> _checkAccess() async {
    if (widget.role != UserRole.admin) {
      final boxChats = await _chatboxDBHelper.getBoxChatsByUser(widget.userId);
      if (!boxChats.any((box) => box.boxChatId == widget.boxChatId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bạn không có quyền truy cập hộp thoại này'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _dbHelper.getMessagesByBoxChat(widget.boxChatId);
      setState(() {
        _messages.addAll(messages);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể tải tin nhắn'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _sendMessage({String? filePath, bool isFile = false}) async {
    if (widget.role != UserRole.admin) {
      String content = isFile ? filePath! : _controller.text.trim();
      if (content.isEmpty) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('userId');
        if (userId == null || userId != widget.userId) {
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }

        if (!isFile) {
          final bannedWords = await RequestDBHelper().getBannedWords();
          if (bannedWords.any(
            (word) => content.toLowerCase().contains(word.word.toLowerCase()),
          )) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Tin nhắn chứa ngôn ngữ không phù hợp. Vui lòng chỉnh sửa.',
                ),
                backgroundColor: Colors.red.shade400,
              ),
            );
            return;
          }
        }

        final message = Message(
          messageId: 0,
          boxChatId: widget.boxChatId,
          senderUserId: widget.userId,
          content: content,
          sentAt: DateTime.now(),
          isFile: isFile,
          isDeleted: false,
        );

        final newMessageId = await _dbHelper.insertMessage(message);
        if (newMessageId == 0) {
          throw Exception('Failed to insert message');
        }

        final newMessage = Message(
          messageId: newMessageId,
          boxChatId: message.boxChatId,
          senderUserId: message.senderUserId,
          content: message.content,
          sentAt: message.sentAt,
          isFile: isFile,
          isDeleted: message.isDeleted,
        );

        setState(() {
          _messages.add(newMessage);
          if (!isFile) _controller.clear();
          _showEmojiPicker = false;
        });
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể gửi tin nhắn'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy('${directory.path}/$fileName');
      await _sendMessage(filePath: savedFile.path, isFile: true);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = result.files.single.name;
      final savedFile = await File(result.files.single.path!).copy('${directory.path}/$fileName');
      await _sendMessage(filePath: savedFile.path, isFile: true);
    }
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'custom_background_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(pickedFile.path).copy('${directory.path}/$fileName');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_background', savedFile.path);
      setState(() {}); // Refresh UI to show new background
    }
  }

  Future<void> _closeAndDeleteBoxChat() async {
    try {
      await _chatboxDBHelper.deleteBoxChat(widget.boxChatId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Box chat đã được đóng và xóa'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error closing and deleting box chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể đóng và xóa box chat'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _addEmoji(String emoji) {
    setState(() {
      _controller.text += emoji;
      _showEmojiPicker = false;
    });
  }

  Widget _buildMessageContent(Message message) {
    if (message.isFile) {
      final isImage = message.content.toLowerCase().endsWith('.jpg') ||
          message.content.toLowerCase().endsWith('.png') ||
          message.content.toLowerCase().endsWith('.jpeg');
      return GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mở file: ${message.content}')),
          );
        },
        child: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(message.content),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
              )
            : Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Colors.blue, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.content.split('/').last,
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      );
    }
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 16,
        color: message.senderUserId == widget.userId
            ? Colors.black87
            : const Color(0xFF1F2937),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('chat_background')),
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Hộp Thoại',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Color(0xFF1F2937),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFEDE9FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFBBF24)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.wallpaper, color: Color(0xFFFBBF24)),
                onPressed: _pickBackgroundImage,
                tooltip: 'Chọn nền',
              ),
              if (widget.role == UserRole.admin)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Xóa Hộp Thoại',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: const Text('Bạn có chắc muốn xóa hộp thoại này?'),
                        actions: [
                          TextButton(
                            child: const Text(
                              'Hủy',
                              style: TextStyle(color: Colors.black54),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          TextButton(
                            child: const Text(
                              'Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    ).then((confirm) {
                      if (confirm == true) {
                        _closeAndDeleteBoxChat();
                      }
                    });
                  },
                  tooltip: 'Xóa Hộp Thoại',
                ),
              if (widget.role != UserRole.admin)
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFFBBF24)),
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Đóng và Xóa Hộp Thoại',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: const Text(
                          'Bạn hài lòng với câu trả lời và muốn đóng hộp thoại này không?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Đóng và Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ).then((confirm) {
                      if (confirm == true) {
                        _closeAndDeleteBoxChat();
                      }
                    });
                  },
                  tooltip: 'Đóng',
                ),
            ],
          ),
          body: Stack(
            children: [
              // Background Image or Fallback Gradient
              Positioned.fill(
                child: snapshot.hasData && snapshot.data != null
                    ? Image.file(
                        File(snapshot.data!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/wallpaper_1.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEDE9FE), Color(0xFFD1D5DB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Image.asset(
                        'assets/wallpaper_1.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFEDE9FE), Color(0xFFD1D5DB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
              ),
              // Semi-transparent overlay for readability
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              // Chat Content
              Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 4.0,
                            ),
                          )
                        : _messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 60,
                                      color: Color(0xFFFBBF24),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Bắt Đầu Trò Chuyện!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isSentByUser = message.senderUserId == widget.userId;
                                  return Align(
                                    alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      padding: const EdgeInsets.all(12),
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSentByUser ? const Color(0xFFFCD34D) : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(20).copyWith(
                                          topLeft: isSentByUser ? const Radius.circular(20) : const Radius.circular(4),
                                          topRight: isSentByUser ? const Radius.circular(4) : const Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 3,
                                            offset: const Offset(1, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildMessageContent(message),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${message.sentAt.hour}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSentByUser ? Colors.black54 : const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  if (widget.role != UserRole.admin)
                    Column(
                      children: [
                        if (_showEmojiPicker)
                          Container(
                            height: 60,
                            color: const Color(0xFFF3F4F6),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: _emojis.length,
                              itemBuilder: (context, index) {
                                return IconButton(
                                  icon: Text(
                                    _emojis[index],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  onPressed: () => _addEmoji(_emojis[index]),
                                );
                              },
                            ),
                          ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.emoji_emotions,
                                    color: Color(0xFFFBBF24),
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showEmojiPicker = !_showEmojiPicker;
                                    });
                                  },
                                  tooltip: 'Chọn biểu tượng cảm xúc',
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.image,
                                    color: Color(0xFFFBBF24),
                                    size: 28,
                                  ),
                                  onPressed: _pickImage,
                                  tooltip: 'Gửi ảnh',
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.attach_file,
                                    color: Color(0xFFFBBF24),
                                    size: 28,
                                  ),
                                  onPressed: _pickFile,
                                  tooltip: 'Gửi tệp',
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      hintText: 'Nhập tin nhắn...',
                                      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: const TextStyle(color: Color(0xFF1F2937)),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Color(0xFFFBBF24),
                                    size: 28,
                                  ),
                                  onPressed: _sendMessage,
                                  tooltip: 'Gửi tin nhắn',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}