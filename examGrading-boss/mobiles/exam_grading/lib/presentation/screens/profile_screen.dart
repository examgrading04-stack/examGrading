import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  late User _user;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _nameController.text = _user.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    if (cloudName == null || uploadPreset == null) {
      debugPrint('Cloudinary config missing in .env');
      return null;
    }

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อกับ Cloudinary (Timeout)'),
    );
    if (response.statusCode != 200) {
      debugPrint('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }

    final respStr = await response.stream.bytesToString();
    final data = json.decode(respStr);
    return data['secure_url'] as String?;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final cloudUrl = await _uploadToCloudinary(File(pickedFile.path));
      if (cloudUrl == null) {
        throw Exception('อัปโหลดรูปล้มเหลว');
      }

      await _user.updatePhotoURL(cloudUrl);
      await _user.reload();
      setState(() {
        _user = _auth.currentUser!;
      });

      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'สำเร็จ',
        text: 'อัปเดตรูปโปรไฟล์เรียบร้อยแล้ว',
      );
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _user.updateDisplayName(newName);
      await _user.reload();
      setState(() {
        _user = _auth.currentUser!;
      });
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'สำเร็จ',
        text: 'อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว',
      );
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'ยืนยันการออกจากระบบ',
      text: 'คุณต้องการออกจากระบบใช่หรือไม่?',
      confirmBtnText: 'ใช่',
      cancelBtnText: 'ยกเลิก',
      showCancelBtn: true,
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await _auth.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _user.photoURL;
    final initial = (_user.displayName?.isNotEmpty == true) 
        ? _user.displayName![0].toUpperCase() 
        : (_user.email?.isNotEmpty == true ? _user.email![0].toUpperCase() : 'A');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('โปรไฟล์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2563EB), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: photoUrl != null
                              ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(FontAwesomeIcons.camera, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'ชื่อแสดงผล',
                      labelStyle: TextStyle(fontSize: 12),
                      hintText: 'กรอกชื่อแสดงผลของคุณ',
                      border: InputBorder.none,
                      icon: Icon(FontAwesomeIcons.user, color: Color(0xFF64748B), size: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(FontAwesomeIcons.envelope, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 16),
                      Text(
                        _user.email ?? '',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Center(
                      child: Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(FontAwesomeIcons.powerOff, color: Colors.red, size: 16),
                    label: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.08),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: SpinKitCircle(color: Colors.white, size: 70.0),
              ),
            ),
        ],
      ),
    );
  }
}
