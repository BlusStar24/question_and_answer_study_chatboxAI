import 'package:flutter/material.dart';
import '../database/models.dart';
import '../chat_view.dart';
import '../../database/request_table.dart';
import '../../database/box_chat_table.dart';
import '../../database/teacher_table.dart';

class RequestManagementView extends StatefulWidget {
  const RequestManagementView({Key? key}) : super(key: key);

  @override
  State<RequestManagementView> createState() => _RequestManagementViewState();
}

class _RequestManagementViewState extends State<RequestManagementView> {
  final RequestDBHelper _requestDBHelper = RequestDBHelper();
  final ChatboxDBHelper _chatboxDBHelper = ChatboxDBHelper();
  List<Request> _pendingRequests = [];
  List<Teacher> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final requests = await _requestDBHelper.getRequestsByStatus('pending');
      final teachers = await TeacherDBHelper().getAllTeachers();

      print('Có ${teachers.length} giáo viên để phân công');
      for (var t in teachers) {
        print('GV: ${t.fullName} (${t.userId})');
      }

      setState(() {
        _pendingRequests = requests;
        _teachers = teachers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi tải dữ liệu: $e',
            style: const TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _approveRequest(Request request, int? selectedTeacherId) async {
    if (selectedTeacherId == null && request.receiverUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn giảng viên để phân công',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Color.fromARGB(255, 239, 83, 80),
        ),
      );
      return;
    }

    try {
      final teacherId = selectedTeacherId ?? request.receiverUserId!;
      await _requestDBHelper.approveRequest(request.requestId, teacherId);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Đã duyệt request và tạo hộp thoại',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi duyệt request: $e',
            style: const TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _rejectRequest(Request request) async {
    try {
      final result = await _requestDBHelper.updateRequestStatus(
        request.requestId,
        RequestStatus.rejected,
      );
      if (result > 0) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã từ chối request',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            backgroundColor: Color.fromARGB(255, 239, 83, 80),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không tìm thấy request để từ chối',
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            backgroundColor: Color.fromARGB(255, 239, 83, 80),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi từ chối request: $e',
            style: const TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _deleteBoxChat(int boxChatId) async {
    try {
      await _chatboxDBHelper.deleteBoxChat(boxChatId);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã xóa hộp thoại',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Color.fromARGB(255, 239, 83, 80),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi xóa hộp thoại: $e',
            style: const TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _showRequestDetails(BuildContext context, Request request) {
    int? selectedTeacherId = request.receiverUserId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Chi tiết Request #${request.requestId}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              color: Color(0xFF01579B),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinh viên ID: ${request.studentUserId}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Danh mục: ${request.questionType}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tiêu đề: ${request.title}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nội dung: ${request.content}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                if (request.attachedFilePath != null)
                  Text(
                    'Tệp đính kèm: ${request.attachedFilePath!.split('/').last}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 12),
                if (request.receiverUserId != null)
                  Text(
                    'Giảng viên: ${_teachers.firstWhere(
                      (t) => t.userId == request.receiverUserId,
                      orElse: () => Teacher(userId: request.receiverUserId!, teacherCode: 'N/A', fullName: 'Không tìm thấy', gender: Gender.male, dateOfBirth: DateTime.now(), profileImage: '', isDeleted: false),
                    ).fullName} ${_teachers.firstWhere(
                          (t) => t.userId == request.receiverUserId,
                          orElse: () => Teacher(userId: request.receiverUserId!, teacherCode: 'N/A', fullName: 'Không tìm thấy', gender: Gender.male, dateOfBirth: DateTime.now(), profileImage: '', isDeleted: false),
                        ).fullName.contains('Hỗ trợ') ? '(Giáo viên hỗ trợ)' : ''}', // SỬA: Hiển thị (Giáo viên hỗ trợ) nếu fullName chứa "Hỗ trợ"
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.black87,
                    ),
                  ),
                if (request.receiverUserId == null &&
                    request.status == RequestStatus.pending)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phân công giảng viên',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF01579B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedTeacherId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF01579B),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _teachers.isEmpty
                            ? [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text(
                                    'Không có giảng viên',
                                    style: TextStyle(fontFamily: 'Roboto'),
                                  ),
                                ),
                              ]
                            : _teachers.map((teacher) {
                                return DropdownMenuItem<int>(
                                  value: teacher.userId,
                                  child: Text(
                                    '${teacher.fullName}${teacher.fullName.contains('Hỗ trợ') ? ' (Giáo viên hỗ trợ)' : ''}', // SỬA: Hiển thị (Giáo viên hỗ trợ) trong dropdown
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                );
                              }).toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedTeacherId = val),
                        hint: const Text(
                          'Chọn giảng viên',
                          style: TextStyle(fontFamily: 'Roboto'),
                        ),
                      ),
                    ],
                  ),
                if (request.status == RequestStatus.approved &&
                    request.boxChatId != null)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                userId: 0,
                                receiverId: request.studentUserId,
                                boxChatId: request.boxChatId!,
                                role: UserRole.admin,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF01579B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Xem Hộp Thoại',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Xóa Hộp Thoại',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xFF01579B),
                                ),
                              ),
                              content: const Text(
                                'Bạn có chắc muốn xóa hộp thoại này?',
                                style: TextStyle(fontFamily: 'Roboto'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                                    'Xóa',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).then((confirm) {
                            if (confirm == true) {
                              _deleteBoxChat(request.boxChatId!);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Xóa Hộp Thoại',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            if (request.status == RequestStatus.pending)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontFamily: 'Roboto', color: Colors.black54),
                ),
              ),
            if (request.status == RequestStatus.pending)
              TextButton(
                onPressed: () {
                  _rejectRequest(request);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Từ chối',
                  style: TextStyle(fontFamily: 'Roboto', color: Colors.red),
                ),
              ),
            if (request.status == RequestStatus.pending)
              TextButton(
                onPressed: () {
                  if (selectedTeacherId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng chọn giảng viên',
                          style: TextStyle(fontFamily: 'Roboto'),
                        ),
                        backgroundColor: Color.fromARGB(255, 233, 79, 76),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _approveRequest(request, selectedTeacherId);
                },
                child: const Text(
                  'Duyệt',
                  style: TextStyle(fontFamily: 'Roboto', color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
      appBar: AppBar(
        title: const Text(
          'Quản lý Request',
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
              colors: [Color(0xFF01579B), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
      ),
      body: _pendingRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Color(0xFF0288D1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có request chờ xử lý',
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
              padding: const EdgeInsets.all(16),
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                final request = _pendingRequests[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showRequestDetails(context, request),
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
                        subtitle: Text(
                          'Danh mục: ${request.questionType}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.black54,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF0288D1),
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
