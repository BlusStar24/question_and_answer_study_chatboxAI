import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../chat_view.dart';
import '../../database/teacher_table.dart';
import '../../database/box_chat_table.dart';
import '../../database/models.dart';
import '../teacher/form_downloads_view.dart';

// Define _FeatureCardData before _TeacherScreenState
class _FeatureCardData {
  final String title;
  final IconData icon;

  const _FeatureCardData(this.title, this.icon);
}

// Placeholder RequestListView widget
class RequestListView extends StatelessWidget {
  final int userId;

  const RequestListView({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.help_outline,
            size: 80,
            color: Color(0xFFFBBF24), // Warm yellow
          ),
          const SizedBox(height: 20),
          Text(
            'Danh sách câu hỏi (User ID: $userId)',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class TeacherScreen extends StatefulWidget {
  final int userId;

  const TeacherScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _currentIndex = 0;
  Teacher? _teacher;
  bool _isLoadingProfile = true;

  final List<_FeatureCardData> _features = [
    _FeatureCardData('Tổng quan', Icons.dashboard),
    _FeatureCardData('Danh sách câu hỏi', Icons.help_outline),
    _FeatureCardData('Danh sách sinh viên', Icons.group),
    _FeatureCardData('Tải biểu mẫu', Icons.file_download),
    _FeatureCardData('Hộp thoại', Icons.chat),
    _FeatureCardData('Thông báo', Icons.notifications),
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final teacherDBHelper = TeacherDBHelper();
      final teacher = await teacherDBHelper.getTeacherByUserId(widget.userId);
      setState(() {
        _teacher = teacher;
        _isLoadingProfile = false;
      });
    } catch (e) {
      print('Error loading teacher profile: $e');
      setState(() => _isLoadingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể tải thông tin cá nhân'),
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
    if (_features[index].title == 'Danh sách câu hỏi') {
      setState(() {
        _currentIndex = 1;
      });
    } else if (_features[index].title == 'Hộp thoại') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatListScreen(userId: widget.userId, role: UserRole.teacher),
        ),
      );
    } else if (_features[index].title == 'Tải biểu mẫu') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DownloadFormsScreen()),
      );
    }
    else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE), // Soft purple background
      appBar: AppBar(
        title: Text(
          'Giảng Viên',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937), // Dark gray for text
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.logout,
            color: Color(0xFFFBBF24),
          ), // Warm yellow
          onPressed: () {
            showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text('Xác nhận đăng xuất'),
                content: const Text('Bạn có chắc muốn đăng xuất không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Color(0xFFFBBF24)),
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
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0, // Square cards
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
            RequestListView(userId: widget.userId), // Placeholder widget
            _isLoadingProfile
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
                  )
                : _teacher == null
                ? const Center(
                    child: Text(
                      'Không tìm thấy thông tin giảng viên.',
                      style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF3F4F6), // Light gray
                                Color(0xFFEDE9FE), // Soft purple
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: const Color(
                                  0xFFFBBF24,
                                ), // Warm yellow
                                child: const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _teacher!.fullName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Mã giảng viên: ${_teacher!.teacherCode}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Profile Details
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thông tin cá nhân',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildProfileField(
                                    icon: Icons.person_outline,
                                    label: 'Họ tên',
                                    value: _teacher!.fullName,
                                  ),
                                  const Divider(height: 24),
                                  _buildProfileField(
                                    icon: Icons.wc,
                                    label: 'Giới tính',
                                    value: _teacher!.gender
                                        .toString()
                                        .split('.')
                                        .last,
                                  ),
                                  const Divider(height: 24),
                                  _buildProfileField(
                                    icon: Icons.cake,
                                    label: 'Ngày sinh',
                                    value: _teacher!.dateOfBirth
                                        .toString()
                                        .split(' ')[0],
                                  ),
                                ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(
          0xFFFBBF24,
        ), // Warm yellow for active item
        unselectedItemColor: const Color(0xFF6B7280),
        backgroundColor: Colors.white,
        elevation: 6,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.reply_all),
            label: 'Câu hỏi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFFFBBF24), // Warm yellow
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF3F4F6), // Light gray
                Color(0xFFEDE9FE), // Soft purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: const Color(0xFFFBBF24), // Warm yellow
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            const Icon(
              Icons.construction,
              size: 80,
              color: Color(0xFFFBBF24), // Warm yellow
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tính năng đang được phát triển...',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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
          content: const Text('Không thể tải danh sách hộp thoại'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE), // Soft purple background
      appBar: AppBar(
        title: const Text('Danh sách hộp thoại'),
        backgroundColor: const Color(0xFFF3F4F6),
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFD1D5DB))),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
            )
          : _boxChats.isEmpty
          ? const Center(
              child: Text(
                'Không có hộp thoại nào',
                style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _boxChats.length,
              itemBuilder: (context, index) {
                final boxChat = _boxChats[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFBBF24), // Warm yellow
                      child: Text(
                        '#${boxChat.boxChatId}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      'Hộp thoại #${boxChat.boxChatId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: Text(
                      'Yêu cầu ID: ${boxChat.requestId}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
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
                  ),
                );
              },
            ),
    );
  }
}
