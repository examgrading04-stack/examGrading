import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quickalert/quickalert.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:exam_grading/config/api_config.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/screens/camera_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _openCustomCamera() async {
    final scannedImage = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (scannedImage != null && mounted) {
      setState(() {
        _image = scannedImage;
      });
    }
  }

  Future<void> _uploadAndProcess({bool overwrite = false}) async {
    if (_image == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณาเลือกรูปภาพกระดาษคำตอบ',
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uid = AuthService.instance.currentEmail ?? '';

      final uri = ApiConfig.endpoint('/api/scan');
      final request = http.MultipartRequest('POST', uri)
        ..fields['user_email'] = uid
        ..fields['overwrite'] = overwrite.toString()
        ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อกับ Server'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!mounted || !context.mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'สแกนสำเร็จ! ได้ ${result['score']} / ${result['total']} คะแนน',
          confirmBtnColor: AppColors.primary,
          onConfirmBtnTap: () {
            Navigator.pop(context); // close alert
            setState(() {
              _image = null;
            });
          },
        );
      } else if (response.statusCode == 409) {
        if (!mounted || !context.mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.confirm,
          title: 'สแกนซ้ำ',
          text:
              'กระดาษคำตอบของนักเรียนคนนี้ถูกสแกนไปแล้ว ต้องการสแกนทับ (อัปเดตคะแนนใหม่) หรือไม่?',
          confirmBtnText: 'สแกนทับ',
          cancelBtnText: 'ยกเลิก',
          confirmBtnColor: AppColors.primary,
          onConfirmBtnTap: () {
            Navigator.pop(context); // close alert
            _uploadAndProcess(overwrite: true);
          },
        );
      } else {
        Map<String, dynamic>? err;
        try {
          err = json.decode(response.body);
        } catch (_) {}
        final detail =
            err?['detail'] ?? 'สแกนไม่สำเร็จ (${response.statusCode})';
        throw Exception(detail);
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'ผิดพลาด',
        text: e.toString().replaceAll('Exception: ', ''),
        confirmBtnColor: AppColors.primary,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.only(
          top: 24,
          left: 28,
          right: 28,
          bottom: 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'เลือกเปลี่ยนรูปภาพ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: FontAwesomeIcons.camera,
                  label: 'ถ่ายภาพ',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _openCustomCamera();
                  },
                ),
                _buildPickerOption(
                  icon: FontAwesomeIcons.solidImage,
                  label: 'อัลบั้มภาพ',
                  color: const Color(0xFF7C3AED),
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
              color: color.withValues(alpha: 0.1),
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'สแกนกระดาษคำตอบ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(color: AppColors.surface),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              FontAwesomeIcons.qrcode,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ตรวจจาก QR บนกระดาษคำตอบ',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'สแกนหรือเลือกภาพก่อน แล้วกดอัปโหลดเมื่อพร้อม',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _image != null
                      ? GestureDetector(
                          onTap: _showPickerBottomSheet,
                          child: Container(
                            height: 420,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_image!, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 24,
                                    right: 24,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              FontAwesomeIcons.penToSquare,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'เปลี่ยนรูป',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              height: 280,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        FontAwesomeIcons.image,
                                        size: 32,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'ยังไม่มีรูปภาพ',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'โปรดถ่ายภาพหรือเลือกจากอัลบั้ม',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _openCustomCamera,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                        boxShadow: AppColors.softShadow,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.camera,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'ถ่ายภาพ',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        _pickImage(ImageSource.gallery),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF7C3AED,
                                          ).withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: AppColors.softShadow,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.solidImage,
                                            color: const Color(0xFF7C3AED),
                                            size: 24,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'อัลบั้มภาพ',
                                            style: TextStyle(
                                              color: const Color(0xFF7C3AED),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                  const SizedBox(height: 32),

                  // Upload Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: _image == null
                          ? AppColors.border
                          : AppColors.primary,
                      boxShadow: [
                        if (_image != null) ...AppColors.primaryShadow,
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isUploading || _image == null
                          ? null
                          : _uploadAndProcess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isUploading
                          ? const SpinKitThreeBounce(
                              color: Colors.white,
                              size: 24,
                            )
                          : Text(
                              'อัปโหลดและประมวลผล',
                              style: TextStyle(
                                fontSize: 16,
                                color: _image == null
                                    ? AppColors.textMuted
                                    : Colors.white,
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
