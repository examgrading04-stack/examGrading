import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quickalert/quickalert.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:exam_grading/config/api_config.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  final picker = ImagePicker();
  final _examIdController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    if (cloudName == null || uploadPreset == null) {
      debugPrint('Cloudinary config missing in .env');
      return null;
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () =>
          throw Exception('หมดเวลาเชื่อมต่อกับ Cloudinary (Timeout)'),
    );
    if (response.statusCode != 200) {
      debugPrint('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }

    final respStr = await response.stream.bytesToString();
    final data = json.decode(respStr);
    return data['secure_url'] as String?;
  }

  Future<void> _uploadAndProcess() async {
    if (_image == null || _examIdController.text.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณาเลือกรูปภาพและระบุรหัสข้อสอบ',
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Upload to Cloudinary
      final cloudUrl = await uploadToCloudinary(_image!);
      if (cloudUrl == null) {
        throw Exception('อัปโหลดรูปล้มเหลว (Cloudinary)');
      }

      final uid = FirebaseAuth.instance.currentUser!.email!;

      // 2. Call FastAPI
      final response = await http
          .post(
            ApiConfig.endpoint('/api/scan-cloudinary'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'exam_id': _examIdController.text.trim(),
              'image_url': cloudUrl,
              'user_email': uid,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
              'หมดเวลาเชื่อมต่อ Server: ${ApiConfig.baseUrl}',
            ),
          );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'สแกนสำเร็จ! ได้ ${result['score']} / ${result['total']} คะแนน',
          confirmBtnColor: const Color(0xFFEC4899),
          onConfirmBtnTap: () {
            Navigator.pop(context); // close alert
            Navigator.pop(context); // close screen
          },
        );
      } else {
        throw Exception('สแกนไม่สำเร็จ (API Error): ${response.body}');
      }
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'เลือกวิธีอัปโหลด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: FontAwesomeIcons.camera,
                  label: 'ถ่ายรูป',
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildPickerOption(
                  icon: FontAwesomeIcons.solidImage,
                  label: 'แกลเลอรี',
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Icon(icon, color: color, size: 28)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFEC4899),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'สแกนกระดาษคำตอบ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ข้อมูลการสอบ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _examIdController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'กรอกรหัสข้อสอบ',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              labelText: 'รหัสข้อสอบ (Exam ID)',
                              labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                              prefixIcon: Icon(
                                FontAwesomeIcons.hashtag,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image Picker Box
                  GestureDetector(
                    onTap: _showPickerBottomSheet,
                    child: Container(
                      height: 380,
                      decoration: BoxDecoration(
                        color: _image != null
                            ? Colors.black
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: _image == null
                            ? Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 2,
                              )
                            : null,
                        boxShadow: [
                          if (_image != null)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_image!, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.5),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'เปลี่ยนรูป',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF2F8),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFEC4899,
                                        ).withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      FontAwesomeIcons.camera,
                                      size: 30,
                                      color: Color(0xFFEC4899),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'แตะเพื่อเลือกรูปภาพ',
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'กระดาษคำตอบต้องอยู่ในกรอบ ชัดเจน และสว่างเพียงพอ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upload Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadAndProcess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isUploading
                          ? const SpinKitThreeBounce(
                              color: Colors.white,
                              size: 24,
                            )
                          : const Text(
                              'อัปโหลดและประมวลผล',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
