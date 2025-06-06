import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/models.dart';
import '../../database/student_table.dart';

class StudentManagementView extends StatefulWidget {
  final VoidCallback? onBack;

  const StudentManagementView({Key? key, this.onBack}) : super(key: key);

  @override
  State<StudentManagementView> createState() => _StudentManagementViewState();
}

class _StudentManagementViewState extends State<StudentManagementView> {
  final StudentDBHelper _dbHelper = StudentDBHelper();

  List<Student> _students = [];
  Student? _selectedStudent;

  final _nameController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _classNameController = TextEditingController();
  final _majorController = TextEditingController();
  Gender _gender = Gender.male;
  DateTime? _dob;
  File? _imageFile;
  int _intakeYear = DateTime.now().year;
  bool _isNew = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final list = await _dbHelper.getAllStudents();
      setState(() {
        _students = list;
        if (!_isNew && list.isNotEmpty) _selectStudent(list[0]);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách học sinh: $e')),
      );
    }
  }

  void _selectStudent(Student s) {
    _selectedStudent = s;
    _nameController.text = s.fullName;
    _placeOfBirthController.text = s.placeOfBirth;
    _classNameController.text = s.className;
    _majorController.text = s.major;
    _gender = s.gender;
    _dob = s.dateOfBirth;
    _intakeYear = s.intakeYear;
    _imageFile =
        (s.profileImage.isNotEmpty && !Uri.parse(s.profileImage).isAbsolute)
        ? File(s.profileImage)
        : null;
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
      initialDate: _dob ?? DateTime(now.year - 18),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _newStudent() {
    _selectedStudent = null;
    _nameController.clear();
    _placeOfBirthController.clear();
    _classNameController.clear();
    _majorController.clear();
    _gender = Gender.male;
    _dob = null;
    _imageFile = null;
    _intakeYear = DateTime.now().year;
    _isNew = true;
    setState(() {});
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final placeOfBirth = _placeOfBirthController.text.trim();
    final className = _classNameController.text.trim();
    final major = _majorController.text.trim();

    if (name.isEmpty ||
        placeOfBirth.isEmpty ||
        className.isEmpty ||
        major.isEmpty ||
        _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng điền đầy đủ họ tên, nơi sinh, lớp, chuyên ngành và ngày sinh',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_isNew) {
        final newStudent = Student(
          userId: 0,
          studentCode: '',
          fullName: name,
          gender: _gender,
          dateOfBirth: _dob!,
          placeOfBirth: placeOfBirth,
          className: className,
          intakeYear: _intakeYear,
          major: major,
          profileImage: _imageFile?.path ?? '',
          isDeleted: false,
        );

        final created = await _dbHelper.insertStudent(newStudent);
        if (created != null) {
          await _loadStudents();
          _selectStudent(created);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thêm học sinh thành công: ${created.studentCode}'),
            ),
          );
        }
      } else {
        if (_selectedStudent == null) return;
        final updated = Student(
          userId: _selectedStudent!.userId,
          studentCode: _selectedStudent!.studentCode,
          fullName: name,
          gender: _gender,
          dateOfBirth: _dob!,
          placeOfBirth: placeOfBirth,
          className: className,
          intakeYear: _intakeYear,
          major: major,
          profileImage: _imageFile?.path ?? _selectedStudent!.profileImage,
          isDeleted: false,
        );
        final result = await _dbHelper.updateStudent(updated);
        if (result > 0) {
          await _loadStudents();
          _selectStudent(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin học sinh thành công'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin học sinh thất bại'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu học sinh: $e')));
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

  Widget _buildIntakeYearPicker() {
    final currentYear = DateTime.now().year;
    final minYear = 2000;
    final years = List.generate(
      currentYear - minYear + 1,
      (index) => currentYear - index,
    );

    if (!years.contains(_intakeYear)) {
      _intakeYear = currentYear;
    }

    return DropdownButtonFormField<int>(
      value: _intakeYear,
      decoration: const InputDecoration(labelText: 'Năm nhập học'),
      items: years
          .map(
            (year) =>
                DropdownMenuItem(value: year, child: Text(year.toString())),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _intakeYear = value);
      },
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
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'Lưu',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeOfBirthController.dispose();
    _classNameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sinh viên'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Tải lại danh sách',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _newStudent,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Danh sách học sinh
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _students.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final isSelected =
                          _selectedStudent?.userId == student.userId;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.blue.shade50,
                        title: Text(
                          student.fullName,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.blue.shade900
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          student.studentCode,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        onTap: () => _selectStudent(student),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Form chỉnh sửa sinh viên
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildGenderDropdown(),

                      const SizedBox(height: 14),

                      _buildDobPicker(),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _placeOfBirthController,
                        decoration: InputDecoration(
                          labelText: 'Nơi sinh',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _classNameController,
                        decoration: InputDecoration(
                          labelText: 'Lớp',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _majorController,
                        decoration: InputDecoration(
                          labelText: 'Chuyên ngành',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildIntakeYearPicker(),

                      const SizedBox(height: 14),

                      _buildImagePicker(),

                      const SizedBox(height: 28),

                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
