import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/models.dart';
import '../../database/teacher_table.dart';

class TeacherManagementView extends StatefulWidget {
  final VoidCallback? onBack;

  const TeacherManagementView({Key? key, this.onBack}) : super(key: key);

  @override
  State<TeacherManagementView> createState() => _TeacherManagementViewState();
}

class _TeacherManagementViewState extends State<TeacherManagementView> {
  final TeacherDBHelper _dbHelper = TeacherDBHelper();

  List<Teacher> _teachers = [];
  Teacher? _selectedTeacher;

  final _nameController = TextEditingController();
  Gender _gender = Gender.male;
  DateTime? _dob;
  File? _imageFile;
  bool _isNew = false;
  bool _isSaving = false;
  String _teacherType =
      'teacher'; // THÊM: Biến theo dõi loại giáo viên (teacher/assistant)

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final list = await _dbHelper.getAllTeachers();
      setState(() {
        _teachers = list;
        if (!_isNew && list.isNotEmpty) _selectTeacher(list[0]);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách giáo viên: $e')),
      );
    }
  }

  void _selectTeacher(Teacher t) {
    _selectedTeacher = t;
    _nameController.text = t.fullName;
    _gender = t.gender;
    _dob = t.dateOfBirth;
    _imageFile =
        (t.profileImage.isNotEmpty && !Uri.parse(t.profileImage).isAbsolute)
        ? File(t.profileImage)
        : null;
    _teacherType = t.fullName.contains('Hỗ trợ')
        ? 'assistant'
        : 'teacher'; // SỬA: Đặt _teacherType dựa trên fullName
    _isNew = false;
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _newTeacher() {
    _selectedTeacher = null;
    _nameController.clear();
    _gender = Gender.male;
    _dob = null;
    _imageFile = null;
    _teacherType = 'teacher'; // SỬA: Đặt _teacherType mặc định là 'teacher'
    _isNew = true;
    setState(() {});
  }

  Future<void> _save() async {
    String name = _nameController.text.trim();
    if (_teacherType == 'assistant' && !name.contains('Hỗ trợ')) {
      name =
          '$name (Hỗ trợ)'; // SỬA: Thêm "(Hỗ trợ)" vào tên nếu là Giáo viên hỗ trợ
    }

    if (name.isEmpty || _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ họ tên và ngày sinh'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isNew) {
        final newTeacher = Teacher(
          userId: 0,
          teacherCode: '',
          fullName: name,
          gender: _gender,
          dateOfBirth: _dob!,
          profileImage: _imageFile?.path ?? '',
          isDeleted: false,
        );

        final created = await _dbHelper.insertTeacher(newTeacher);
        if (created != null) {
          await _loadTeachers();
          _selectTeacher(created);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thêm giáo viên thành công: ${created.teacherCode}',
              ),
            ),
          );
        }
      } else {
        if (_selectedTeacher == null) return;
        final updated = Teacher(
          teacherCode: _selectedTeacher!.teacherCode,
          userId: _selectedTeacher!.userId,
          fullName: name,
          gender: _gender,
          dateOfBirth: _dob!,
          profileImage: _imageFile?.path ?? _selectedTeacher!.profileImage,
          isDeleted: false,
        );
        await _dbHelper.updateTeacher(updated);
        await _loadTeachers();
        _selectTeacher(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin giáo viên thành công'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu giáo viên: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<Gender>(
      value: _gender,
      decoration: const InputDecoration(labelText: 'Giới tính'),
      items: Gender.values
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g.toString().split('.').last.toUpperCase()),
            ),
          )
          .toList(),
      onChanged: (g) {
        if (g != null) setState(() => _gender = g);
      },
    );
  }

  // THÊM: Hàm tạo dropdown chọn loại giáo viên
  Widget _buildTeacherTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _teacherType,
      decoration: const InputDecoration(
        labelText: 'Loại giáo viên',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'teacher', child: Text('Giáo viên')),
        DropdownMenuItem(value: 'assistant', child: Text('Giáo viên hỗ trợ')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _teacherType = value);
        }
      },
    );
  }

  Widget _buildDobPicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ngày sinh',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dob == null ? '' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
        isEmpty: _dob == null,
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ảnh đại diện',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_imageFile == null ? 'Chưa chọn ảnh' : 'Đã chọn ảnh'),
            const Icon(Icons.image),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _save,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.blue.shade800,
      ),
      child: _isSaving
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Lưu',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị Giáo viên'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeachers,
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: const Text(
                          'Danh sách Giáo viên',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        initiallyExpanded: true,
                        children: _teachers.isEmpty
                            ? [
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Chưa có giáo viên nào'),
                                ),
                              ]
                            : _teachers.map((teacher) {
                                return ListTile(
                                  title: Text(teacher.fullName),
                                  subtitle: Text(teacher.teacherCode),
                                  onTap: () => _selectTeacher(teacher),
                                );
                              }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Thông tin giáo viên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildGenderDropdown(),
                            const SizedBox(height: 8),
                            _buildTeacherTypeDropdown(), // THÊM: Thêm dropdown loại giáo viên
                            const SizedBox(height: 8),
                            _buildDobPicker(),
                            const SizedBox(height: 8),
                            _buildImagePicker(),
                            const SizedBox(height: 16),
                            _buildSaveButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newTeacher,
        child: const Icon(Icons.add),
        tooltip: 'Thêm giáo viên mới',
      ),
    );
  }
}
