import 'package:flutter/material.dart';
import '../../database/account_table.dart';
import '../database/models.dart';
import 'student_management.dart';
import 'teacher_management.dart';
import '../../database/teacher_table.dart'; // THÊM: Import TeacherDBHelper để tra cứu giáo viên

class UserManagementView extends StatefulWidget {
  const UserManagementView({Key? key}) : super(key: key);

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final DBHelper _accountHelper = DBHelper();
  final TeacherDBHelper _teacherDBHelper =
      TeacherDBHelper(); // THÊM: Khởi tạo TeacherDBHelper
  List<Account> _accounts = [];

  String _currentSubView =
      'accountList'; // 'accountList', 'studentManagement', 'teacherManagement'
  String _selectedRoleFilter =
      'all'; // SỬA: Giá trị có thể là 'all', 'student', 'teacher', 'teacher_assistant'

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountHelper.getAllAccounts();
      setState(() {
        _accounts = accounts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách tài khoản: $e')),
      );
    }
  }

  Future<void> _deleteAccount(Account account) async {
    try {
      await _accountHelper.softDeleteAccount(account.userId);
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa tài khoản ${account.username}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa tài khoản: $e')));
    }
  }

  void _showDeleteDialog(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản "${account.username}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteAccount(account);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditAccount(Account account) {
    final _usernameController = TextEditingController(text: account.username);
    final _passwordController = TextEditingController(text: account.password);
    String _selectedRole = account.role
        .toString()
        .split('.')
        .last; // SỬA: Khởi tạo vai trò mặc định
    bool _isAssistant =
        false; // THÊM: Biến để theo dõi trạng thái Giáo viên hỗ trợ

    // THÊM: Tra cứu Teacher để xác định _selectedRole
    _teacherDBHelper.getTeacherByUserId(account.userId).then((teacher) {
      if (teacher != null && teacher.fullName.contains('Hỗ trợ')) {
        setState(() {
          _selectedRole = 'teacher_assistant';
          _isAssistant = true;
        });
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa tài khoản'),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Sinh viên'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Giáo viên'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher_assistant',
                        child: Text('Giáo viên hỗ trợ'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Quản trị viên'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          _selectedRole = value;
                          _isAssistant = value == 'teacher_assistant';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final username = _usernameController.text.trim();
                final password = _passwordController.text.trim();
                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ thông tin'),
                    ),
                  );
                  return;
                }
                try {
                  final updatedAccount = Account(
                    userId: account.userId,
                    username: username,
                    password: password,
                    role: _selectedRole == 'teacher_assistant'
                        ? UserRole.teacher
                        : UserRole.values.firstWhere(
                            (r) =>
                                r.toString().split('.').last == _selectedRole,
                          ),
                    isDeleted: account.isDeleted,
                  );
                  await _accountHelper.updateAccount(updatedAccount);
                  Navigator.pop(context);
                  await _loadAccounts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cập nhật tài khoản $username thành công'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi cập nhật tài khoản: $e')),
                  );
                }
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAccount() {
    final _usernameController = TextEditingController();
    final _passwordController = TextEditingController();
    String _selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo tài khoản mới'),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Sinh viên'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Giáo viên'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher_assistant',
                        child: Text('Giáo viên hỗ trợ'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Quản trị viên'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => _selectedRole = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final username = _usernameController.text.trim();
                final password = _passwordController.text.trim();
                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ thông tin'),
                    ),
                  );
                  return;
                }
                try {
                  final newAccount = Account(
                    userId: 0,
                    username: username,
                    password: password,
                    role: _selectedRole == 'teacher_assistant'
                        ? UserRole.teacher
                        : UserRole.values.firstWhere(
                            (r) =>
                                r.toString().split('.').last == _selectedRole,
                          ),
                    isDeleted: false,
                  );
                  await _accountHelper.insertAccount(newAccount);
                  Navigator.pop(context);
                  await _loadAccounts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tạo tài khoản $username thành công'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi tạo tài khoản: $e')),
                  );
                }
              },
              child: const Text('Tạo', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, size: 32, color: Colors.blueAccent),
      ),
    );
  }

  Future<String> _roleToDisplayName(
    UserRole role, {
    required int userId,
  }) async {
    // SỬA: Thay username bằng userId và trả về Future<String>
    switch (role) {
      case UserRole.student:
        return 'Sinh viên';
      case UserRole.teacher:
        final teacher = await _teacherDBHelper.getTeacherByUserId(
          userId,
        ); // THÊM: Tra cứu Teacher
        return teacher != null && teacher.fullName.contains('Hỗ trợ')
            ? 'Giáo viên hỗ trợ'
            : 'Giáo viên'; // SỬA: Kiểm tra fullName chứa "Hỗ trợ"
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  Future<List<Account>> _filteredAccounts() async {
    // SỬA: Chuyển thành async để tra cứu Teacher
    if (_selectedRoleFilter == 'all') {
      return _accounts;
    } else if (_selectedRoleFilter == 'student') {
      return _accounts.where((acc) => acc.role == UserRole.student).toList();
    } else if (_selectedRoleFilter == 'teacher') {
      return _accounts
          .where((acc) => acc.role == UserRole.teacher)
          .toList(); // SỬA: Lọc tất cả UserRole.teacher
    } else if (_selectedRoleFilter == 'teacher_assistant') {
      // THÊM: Lọc Giáo viên hỗ trợ
      final List<Account> filtered = [];
      for (var acc in _accounts.where((acc) => acc.role == UserRole.teacher)) {
        final teacher = await _teacherDBHelper.getTeacherByUserId(acc.userId);
        if (teacher != null && teacher.fullName.contains('Hỗ trợ')) {
          filtered.add(acc);
        }
      }
      return filtered;
    }
    return _accounts;
  }

  Widget _buildTopIconButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconButton(
            icon: Icons.account_circle,
            onTap: _showCreateAccount,
          ),
          _buildIconButton(
            icon: Icons.school,
            onTap: () => setState(() => _currentSubView = 'studentManagement'),
          ),
          _buildIconButton(
            icon: Icons.person,
            onTap: () => setState(() => _currentSubView = 'teacherManagement'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (_currentSubView) {
      case 'studentManagement':
        content = StudentManagementView(
          onBack: () {
            setState(() {
              _currentSubView = 'accountList';
            });
            _loadAccounts();
          },
        );
        break;

      case 'teacherManagement':
        content = TeacherManagementView(
          onBack: () {
            setState(() {
              _currentSubView = 'accountList';
            });
            _loadAccounts();
          },
        );
        break;

      case 'accountList':
      default:
        content = Column(
          children: [
            _buildTopIconButtons(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedRoleFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Lọc theo vai trò',
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tất cả tài khoản'),
                    ),
                    DropdownMenuItem(
                      value: 'student',
                      child: Text('Sinh viên'),
                    ),
                    DropdownMenuItem(
                      value: 'teacher',
                      child: Text('Giáo viên'),
                    ),
                    DropdownMenuItem(
                      value: 'teacher_assistant',
                      child: Text('Giáo viên hỗ trợ'),
                    ), // THÊM: Tùy chọn lọc Giáo viên hỗ trợ
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRoleFilter = value;
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Account>>(
                // SỬA: Sử dụng FutureBuilder để xử lý async _filteredAccounts
                future: _filteredAccounts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có tài khoản nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }
                  final filteredAccounts = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = filteredAccounts[index];
                      return FutureBuilder<String>(
                        // THÊM: FutureBuilder để lấy role display name
                        future: _roleToDisplayName(
                          account.role,
                          userId: account.userId,
                        ),
                        builder: (context, roleSnapshot) {
                          if (roleSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Đang tải...'),
                              subtitle: Text('Đang tải vai trò...'),
                            );
                          }
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(account.username),
                              subtitle: Text(
                                roleSnapshot.data ?? 'Không xác định',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () => _showEditAccount(account),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _showDeleteDialog(account),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản người dùng'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(221, 9, 103, 190),
        elevation: 1,
        leading: _currentSubView == 'accountList'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.black87,
                onPressed: () {
                  setState(() {
                    _currentSubView = 'accountList';
                  });
                  _loadAccounts();
                },
              ),
      ),
      body: content,
    );
  }
}
