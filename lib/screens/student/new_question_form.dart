import 'package:flutter/material.dart';
import '../../database/models.dart';
import '../../database/account_table.dart';
import '../../database/request_table.dart';

class NewQuestionForm extends StatefulWidget {
  final int userId;

  const NewQuestionForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<NewQuestionForm> createState() => _NewQuestionFormState();
}

class _NewQuestionFormState extends State<NewQuestionForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _categories = ['Học tập', 'Học phí', 'Thủ tục hành chính'];
  String? _selectedCategory;
  bool _selectTeacher = false;
  int? _selectedTeacherId;
  List<Teacher> _teachers = [];
  final _dbHelper = DBHelper();
  final _requestDBHelper = RequestDBHelper();

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final teachers = await _dbHelper.getTeachers();
    setState(() {
      _teachers = teachers;
    });
  }

  Future<void> _submitQuestion() async {
    if (_selectedCategory == null ||
        _titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        (_selectTeacher && _selectedTeacherId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Vui lòng điền đầy đủ thông tin',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    try {
      final newRequest = Request(
        requestId: 0,
        studentUserId: widget.userId,
        questionType: _selectedCategory!,
        title: _titleController.text,
        content: _contentController.text,
        attachedFilePath: null,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        receiverUserId: _selectedTeacherId,
      );

      await _requestDBHelper.insertRequest(newRequest);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Đã gửi câu hỏi thành công, chờ admin xử lý',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );

      setState(() {
        _selectedCategory = null;
        _titleController.clear();
        _contentController.clear();
        _selectTeacher = false;
        _selectedTeacherId = null;
      });

      Navigator.pop(context);
    } catch (e) {
      print('Error submitting question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Lỗi khi gửi câu hỏi',
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
      backgroundColor: const Color(0xFFEFF3F6),
      appBar: AppBar(
        title: const Text(
          'Tạo Câu Hỏi Mới',
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
        automaticallyImplyLeading: false, // Loại bỏ nút back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại câu hỏi',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
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
                    color: Color(0xFF1976D2),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _categories
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(fontFamily: 'Roboto'),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tiêu đề',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
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
                    color: Color(0xFF1976D2),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nội dung',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
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
                    color: Color(0xFF1976D2),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text(
                'Chọn giáo viên để hỏi',
                style: TextStyle(fontFamily: 'Roboto', color: Colors.black87),
              ),
              value: _selectTeacher,
              onChanged: (val) => setState(() => _selectTeacher = val!),
              activeColor: const Color(0xFF1976D2),
              checkColor: Colors.white,
            ),
            if (_selectTeacher)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn giáo viên',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedTeacherId,
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
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Chọn giáo viên',
                      labelStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.black54,
                      ),
                    ),
                    items: _teachers.map((teacher) {
                      return DropdownMenuItem<int>(
                        value: teacher.userId,
                        child: Text(
                          teacher.fullName,
                          style: const TextStyle(fontFamily: 'Roboto'),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedTeacherId = val),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 120,
                      minHeight: 48,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Gửi Câu Hỏi',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
