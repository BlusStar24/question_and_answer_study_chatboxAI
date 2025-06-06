import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_question_form.dart';
import 'faq_list_view.dart';
import '../../database/box_chat_table.dart';
import '../../database/student_table.dart';
import '../../database/models.dart';
import '../../chat_view.dart';
import '../student/form_downloads_view.dart';

class StudentScreen extends StatefulWidget {
  final int userId;

  const StudentScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _currentIndex = 0;
  Student? _student;
  bool _isLoadingProfile = true;

  final List<_FeatureCardData> _features = [
    _FeatureCardData('Tổng quan', Icons.dashboard),
    _FeatureCardData('Câu hỏi thường gặp', Icons.help_outline),
    _FeatureCardData('Đặt câu hỏi mới', Icons.edit_note),
    _FeatureCardData('Tải biểu mẫu', Icons.file_download),
    _FeatureCardData('Hộp thoại', Icons.chat),
    _FeatureCardData('Thông báo', Icons.notifications),
  ];

  OverlayEntry? _chatBubbleOverlay;
  Offset _bubblePosition = const Offset(20, 20);
  bool _isChatOpen = false;
  List<Map<String, String>> _chatHistory = [];
  final _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showChatBubble();
      }
    });
  }

  Future<void> _loadStudentProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final studentDBHelper = StudentDBHelper();
      final student = await studentDBHelper.getStudentByUserId(widget.userId);
      setState(() {
        _student = student;
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('Error loading student profile: $e');
      setState(() => _isLoadingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không thể tải thông tin cá nhân',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      print('UserId removed from SharedPreferences');
    } catch (e) {
      print('Error accessing SharedPreferences: $e');
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _navigateToScreen(int index) {
    if (_features[index].title == 'Câu hỏi thường gặp') {
      setState(() {
        _currentIndex = 1;
      });
    } else if (_features[index].title == 'Đặt câu hỏi mới') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewQuestionForm(userId: widget.userId),
        ),
      );
    } else if (_features[index].title == 'Hộp thoại') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatListScreen(userId: widget.userId, role: UserRole.student),
        ),
      );
    } else if (_features[index].title == 'Tải biểu mẫu') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DownloadFormsScreen()),
      );
    } else {}
  }

  String normalizeMajor(String major) {
    final normalized = major.toLowerCase().replaceAll(' ', '');
    if (normalized == 'congnghethongtin') return 'Công nghệ thông tin';
    if (normalized == 'tritunhantao') return 'Trí tuệ nhân tạo';
    if (normalized == 'kythuatphanmem') return 'Kỹ thuật phần mềm';
    return 'Công nghệ thông tin'; // Giá trị mặc định
  }

  Future<String> askAI(String question, String major) async {
    final normalizedMajor = normalizeMajor(major);
    final url = Uri.parse('http://10.0.2.2:8000/ask');
    print('Gửi yêu cầu: question=$question, major=$normalizedMajor');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': question, 'major': normalizedMajor}),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Yêu cầu hết thời gian chờ (timeout)');
            },
          );
      print('Trả về mã trạng thái: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'];
      } else {
        throw Exception(
          'Lỗi khi gọi API: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Lỗi: $e');
      throw Exception('Lỗi: $e');
    }
  }

  void _showChatBubble() {
    try {
      _chatBubbleOverlay = OverlayEntry(
        builder: (context) => Positioned(
          left: _bubblePosition.dx,
          top: _bubblePosition.dy,
          child: Draggable(
            childWhenDragging: Container(),
            feedback: _buildChatBubble(),
            onDragEnd: (details) {
              setState(() {
                _bubblePosition = Offset(
                  details.offset.dx.clamp(
                    0,
                    MediaQuery.of(context).size.width - 60,
                  ),
                  details.offset.dy.clamp(
                    0,
                    MediaQuery.of(context).size.height - 60,
                  ),
                );
              });
              _chatBubbleOverlay?.markNeedsBuild();
            },
            child: _buildChatBubble(),
          ),
        ),
      );
      Overlay.of(context).insert(_chatBubbleOverlay!);
    } catch (e) {
      print('Error showing chat bubble: $e');
    }
  }

  Widget _buildChatBubble() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isChatOpen = !_isChatOpen;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: const Icon(Icons.chat_bubble, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Positioned(
      bottom: 80,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 320,
          height: 420,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Hướng Dẫn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _isChatOpen = false;
                      });
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: ListView.builder(
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = _chatHistory[index];
                    return ChatMessage(
                      question: chat['question']!,
                      answer: chat['answer']!,
                    );
                  },
                ),
              ),
              const Divider(color: Colors.grey),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn...',
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(fontFamily: 'Roboto'),
                      ),
                      style: const TextStyle(fontFamily: 'Roboto'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1976D2)),
                    onPressed: () async {
                      final question = _questionController.text.trim();
                      if (question.isEmpty) return;

                      try {
                        final major = _student?.major ?? 'Công nghệ thông tin';
                        final answer = await askAI(question, major);
                        setState(() {
                          _chatHistory.add({
                            'question': question,
                            'answer': answer,
                          });
                        });
                        _questionController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Lỗi: $e',
                              style: const TextStyle(fontFamily: 'Roboto'),
                            ),
                            backgroundColor: Colors.red.shade400,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chatBubbleOverlay?.remove();
    _chatBubbleOverlay = null;
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      appBar: AppBar(
        title: const Text(
          'Hệ thống hỗ trợ sinh viên',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () {
            showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Xác nhận đăng xuất',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Bạn có chắc muốn đăng xuất không?',
                  style: TextStyle(fontFamily: 'Roboto'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(fontFamily: 'Roboto', color: Colors.red),
                    ),
                  ),
                ],
              ),
            ).then((confirm) {
              if (confirm == true) {
                _logout();
              }
            });
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: _features
                        .asMap()
                        .entries
                        .map(
                          (entry) => _FeatureCard(
                            title: entry.value.title,
                            icon: entry.value.icon,
                            onTap: () => _navigateToScreen(entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
                FAQListView(userId: widget.userId),
                _isLoadingProfile
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1976D2),
                          strokeWidth: 3,
                        ),
                      )
                    : _student == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Color(0xFFFBC02D),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Không tìm thấy thông tin sinh viên.',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              height: 200,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF42A5F5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage:
                                      _student!.profileImage.isNotEmpty
                                      ? NetworkImage(_student!.profileImage)
                                      : null,
                                  backgroundColor: Colors.white,
                                  child: _student!.profileImage.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF1976D2),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFF5F7FA),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Thông tin cá nhân',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Roboto',
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildProfileItem(
                                          icon: Icons.badge,
                                          label: 'Mã sinh viên',
                                          value: _student!.studentCode,
                                        ),
                                        const Divider(
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                        _buildProfileItem(
                                          icon: Icons.person,
                                          label: 'Họ tên',
                                          value: _student!.fullName,
                                        ),
                                        const Divider(
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                        _buildProfileItem(
                                          icon: Icons.transgender,
                                          label: 'Giới tính',
                                          value: _student!.gender
                                              .toString()
                                              .split('.')
                                              .last,
                                        ),
                                        const Divider(
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                        _buildProfileItem(
                                          icon: Icons.cake,
                                          label: 'Ngày sinh',
                                          value: _student!.dateOfBirth
                                              .toString()
                                              .split(' ')[0],
                                        ),
                                        const Divider(
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                        _buildProfileItem(
                                          icon: Icons.location_on,
                                          label: 'Nơi sinh',
                                          value: _student!.placeOfBirth,
                                        ),
                                        const Divider(
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                        _buildProfileItem(
                                          icon: Icons.class_,
                                          label: 'Lớp',
                                          value: _student!.className,
                                        ),
                                        const Divider(
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                        _buildProfileItem(
                                          icon: Icons.calendar_today,
                                          label: 'Năm nhập học',
                                          value: _student!.intakeYear
                                              .toString(),
                                        ),
                                        const Divider(
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                        _buildProfileItem(
                                          icon: Icons.school,
                                          label: 'Chuyên ngành',
                                          value: _student!.major,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          if (_isChatOpen) _buildChatPanel(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Roboto'),
        onTap: (index) {
          setState(() {
            _currentIndex = index.clamp(0, 2);
          });
          if (index != 2) {
            _navigateToScreen(index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'FAQ'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1976D2), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCardData {
  final String title;
  final IconData icon;

  const _FeatureCardData(this.title, this.icon);
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: const Color(0xFF1976D2)),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                    fontFamily: 'Roboto',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderTab extends StatelessWidget {
  final String title;

  const PlaceholderTab({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 80, color: Color(0xFFFBC02D)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính năng đang được phát triển...',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  final int userId;
  final UserRole role;

  const ChatListScreen({Key? key, required this.userId, required this.role})
    : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatboxDBHelper = ChatboxDBHelper();
  List<BoxChat> _boxChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoxChats();
  }

  Future<void> _loadBoxChats() async {
    setState(() => _isLoading = true);
    try {
      final boxChats = await _chatboxDBHelper.getBoxChatsByUser(widget.userId);
      setState(() {
        _boxChats = boxChats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading box chats: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không thể tải danh sách hộp thoại',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách hộp thoại',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1976D2),
                strokeWidth: 3,
              ),
            )
          : _boxChats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Color(0xFFFBC02D),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có hộp thoại nào',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _boxChats.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final boxChat = _boxChats[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userId: widget.userId,
                            receiverId: boxChat.senderUserId == widget.userId
                                ? boxChat.receiverUserId
                                : boxChat.senderUserId,
                            boxChatId: boxChat.boxChatId,
                            role: widget.role,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'Hộp thoại #${boxChat.boxChatId}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Yêu cầu ID: ${boxChat.requestId}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.black54,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String question;
  final String answer;

  const ChatMessage({required this.question, required this.answer, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const Divider(color: Colors.grey),
        ],
      ),
    );
  }
}
