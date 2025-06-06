import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class DownloadFormsScreen extends StatefulWidget {
  const DownloadFormsScreen({Key? key}) : super(key: key);

  @override
  _DownloadFormsScreenState createState() => _DownloadFormsScreenState();
}

class _DownloadFormsScreenState extends State<DownloadFormsScreen> {
  final List<Map<String, String>> _forms = const [
    {
      'title': 'Đơn xin nghỉ học',
      'description': 'Biểu mẫu để xin phép nghỉ học tạm thời hoặc nghỉ hẳn.',
      'wordUrl':
          'https://drive.google.com/uc?export=download&id=1pXXJVrqu0qR5DRkPVi80wHyKRxbViqbX',
      'pdfUrl':
          'https://drive.google.com/uc?export=download&id=1pXXJVrqu0qR5DRkPVi80wHyKRxbViqbX',
    },
    {
      'title': 'Đơn xin cấp bảng điểm',
      'description': 'Biểu mẫu để yêu cầu cấp bảng điểm chính thức.',
      'wordUrl':
          'https://drive.google.com/uc?export=download&id=1hyTKckPSe0OrM-ziD4sbPgWJ6ZzxVzn4',
      'pdfUrl':
          'https://drive.google.com/uc?export=download&id=1hyTKckPSe0OrM-ziD4sbPgWJ6ZzxVzn4',
    },
    {
      'title': 'Đơn đăng ký tham gia công tác xã hội',
      'description': 'Biểu mẫu đăng ký tham gia công tác xã hội.',
      'wordUrl':
          'https://drive.google.com/uc?export=download&id=18GO19wxpYGjvQ5EiL_gPWL9dO6F12lH1',
      'pdfUrl':
          'https://drive.google.com/uc?export=download&id=18GO19wxpYGjvQ5EiL_gPWL9dO6F12lH1',
    },
    {
      'title': 'Đơn xin gia hạn học phí',
      'description': 'Biểu mẫu để xin gia hạn học phí.',
      'wordUrl':
          'https://drive.google.com/uc?export=download&id=14PI6NBU-QiJHonr5PDizTWK2xp8pyG1E',
      'pdfUrl':
          'https://drive.google.com/uc?export=download&id=14PI6NBU-QiJHonr5PDizTWK2xp8pyG1E',
    },
  ];

  Future<void> _downloadFile(
    String url,
    String fileName,
    BuildContext context,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang tải $fileName...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Lấy thư mục lưu file phù hợp
      Directory? directory;
      if (Platform.isAndroid) {
        // Trên Android, sử dụng thư mục Downloads
        directory = directory = Directory('/storage/emulated/0/Download');
      } else {
        // Trên iOS, sử dụng thư mục Documents
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        // Fallback nếu không lấy được thư mục
        directory = await getApplicationDocumentsDirectory();
      }

      await directory.create(recursive: true);
      final filePath = '${directory.path}/$fileName';

      print('→ Đường dẫn lưu file: $filePath');

      final dio = Dio();
      await dio.download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tải xong $fileName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'MỞ',
            textColor: Colors.white,
            onPressed: () async {
              print('→ Đang mở file: $filePath');
              final result = await OpenFile.open(filePath);
              print('→ Kết quả mở file: ${result.message}');
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không mở được file: ${result.message}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Lỗi khi tải file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải $fileName: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _generateFileName(String title, String format) {
    final cleanTitle = title.replaceAll(' ', '_').toLowerCase();
    return '$cleanTitle.$format';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tải biểu mẫu',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _forms.length,
          itemBuilder: (context, index) {
            final form = _forms[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form['title']!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        form['description']!,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _downloadFile(
                              form['wordUrl']!,
                              _generateFileName(form['title']!, 'docx'),
                              context,
                            ),
                            icon: const Icon(Icons.download, size: 20),
                            label: const Text('Word'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF1976D2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _downloadFile(
                              form['pdfUrl']!,
                              _generateFileName(form['title']!, 'pdf'),
                              context,
                            ),
                            icon: const Icon(Icons.download, size: 20),
                            label: const Text('PDF'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF1976D2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
