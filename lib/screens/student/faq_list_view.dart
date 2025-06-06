import 'package:flutter/material.dart';
import '../../database/request_table.dart';
import '../../database/student_table.dart';
import '../../database/models.dart';
import '../../chat_view.dart';

class FAQListView extends StatefulWidget {
  final int userId;

  const FAQListView({Key? key, required this.userId}) : super(key: key);

  @override
  State<FAQListView> createState() => _FAQListScreenState();
}

class _FAQListScreenState extends State<FAQListView> {
  final _requestDBHelper = RequestDBHelper();
  List<Request> _requests = [];
  bool _isLoading = true;
  Student? _student;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadStudentProfile();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _requestDBHelper.getRequestsByStudent(
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
          content: const Text(
            'Không thể tải danh sách câu hỏi',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _loadStudentProfile() async {
    try {
      final studentDBHelper = StudentDBHelper();
      final student = await studentDBHelper.getStudentByUserId(widget.userId);
      setState(() {
        _student = student;
      });
    } catch (e) {
      print('Error loading student profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      appBar: AppBar(
        title: const Text(
          'Danh sách câu hỏi',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
          : _requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.question_answer_outlined,
                    size: 80,
                    color: Color(0xFFFBC02D),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa có câu hỏi nào',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/new_question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Đặt câu hỏi mới',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap:
                        request.status == RequestStatus.approved &&
                            request.boxChatId != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  userId: widget.userId,
                                  receiverId: request.receiverUserId!,
                                  boxChatId: request.boxChatId!,
                                  role: UserRole.student,
                                ),
                              ),
                            );
                          }
                        : null,
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
                          request.title,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Danh mục: ${request.questionType}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Trạng thái: ${request.status.toString().split('.').last}',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color:
                                        request.status == RequestStatus.approved
                                        ? Colors.green.shade600
                                        : request.status ==
                                              RequestStatus.pending
                                        ? Colors.orange.shade600
                                        : Colors.red.shade600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (request.status == RequestStatus.approved)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                if (request.status == RequestStatus.pending)
                                  const Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                if (request.status == RequestStatus.rejected)
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing:
                            request.status == RequestStatus.approved &&
                                request.boxChatId != null
                            ? const Icon(
                                Icons.chat,
                                color: Color(0xFF1976D2),
                                size: 28,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
