import 'package:flutter/material.dart';
import '../../database/request_table.dart';
import '../../database/teacher_table.dart';
import '../../database/models.dart';
import '../../chat_view.dart';

class RequestListView extends StatefulWidget {
  final int userId;

  const RequestListView({Key? key, required this.userId}) : super(key: key);

  @override
  State<RequestListView> createState() => _RequestListViewState();
}

class _RequestListViewState extends State<RequestListView> {
  final _requestDBHelper = RequestDBHelper();
  List<Request> _requests = [];
  bool _isLoading = true;
  Teacher? _teacher;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadTeacherProfile();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _requestDBHelper.getRequestsByTeacher(
        widget.userId,
      );
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading requests: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể tải danh sách câu hỏi'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final teacherDBHelper = TeacherDBHelper();
      final teacher = await teacherDBHelper.getTeacherByUserId(widget.userId);
      setState(() {
        _teacher = teacher;
      });
    } catch (e) {
      print('Error loading teacher profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE), // Tím nhạt đồng bộ
      appBar: AppBar(
        title: const Text(
          'Danh Sách Câu Hỏi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF3F4F6), // Xám nhạt
                Color(0xFFEDE9FE), // Tím nhạt
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFBBF24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFBBF24)),
            )
          : _requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 80,
                    color: Color(0xFFFBBF24), // Vàng ấm
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có câu hỏi nào được gửi đến bạn',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: request.boxChatId != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  userId: widget.userId,
                                  receiverId: request.studentUserId,
                                  boxChatId: request.boxChatId!,
                                  role: UserRole.teacher,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.question_answer,
                              size: 24,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Danh mục: ${request.questionType}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Trạng thái: ${request.status.toString().split('.').last}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        request.status == RequestStatus.pending
                                        ? Colors.orange
                                        : request.status ==
                                              RequestStatus.approved
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (request.boxChatId != null)
                            const Icon(
                              Icons.chat,
                              size: 24,
                              color: Color(0xFFFBBF24),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
