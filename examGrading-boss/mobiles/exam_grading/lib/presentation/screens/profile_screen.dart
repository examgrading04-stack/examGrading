import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/presentation/screens/login_screen.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';

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

  Future<void> _saveProfileDocument({
    String? displayName,
    String? photoURL,
  }) async {
    final email = _user.email;
    if (email == null || email.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('profiles')
        .doc(email)
        .set({
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        _user = refreshedUser;
      }
      await _saveProfileDocument(
        displayName: _user.displayName ?? _nameController.text.trim(),
        photoURL: cloudUrl,
      );

      if (!mounted) return;
      setState(() {});
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'สำเร็จ',
        text: 'อัปเดตรูปโปรไฟล์เรียบร้อยแล้ว',
        confirmBtnColor: AppColors.success,
      );
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
        confirmBtnColor: AppColors.error,
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
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        _user = refreshedUser;
      }
      await _saveProfileDocument(
        displayName: newName,
        photoURL: _user.photoURL,
      );
      if (!mounted) return;
      setState(() {});
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'สำเร็จ',
        text: 'อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว',
        confirmBtnColor: AppColors.success,
      );
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
        confirmBtnColor: AppColors.error,
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
      confirmBtnColor: AppColors.error,
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top Background (no gradient to match clean theme)
          Container(
            height: 260,
            color: AppColors.surface,
          ),
          // Custom App Bar and Content
          SafeArea(
            child: Column(
              children: [
                // Premium AppBar Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              FontAwesomeIcons.chevronLeft,
                              color: AppColors.textPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'โปรไฟล์ผู้ใช้งาน',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 40), // Balanced spacing
                    ],
                  ),
                ),

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // Layered Avatar Upload Widget
                        GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Glow Layer
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primarySoft,
                                ),
                              ),
                              // Inner Glowing Ring
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                ),
                              ),
                              // Photo Frame
                              Container(
                                width: 98,
                                height: 98,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3.5),
                                  boxShadow: AppColors.softShadow,
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
                                                    color: AppColors.primaryDark,
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                        )
                                      : Container(
                                          color: Colors.white,
                                          child: Center(
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              // Camera Edit Icon
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: AppColors.primaryGradient,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: AppColors.primaryShadow,
                                  ),
                                  child: const Icon(
                                    FontAwesomeIcons.camera,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),

                        // Form Account Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border, width: 1.5),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ข้อมูลและสถานะบัญชี',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Name Form Input (Minimalist Underline Style)
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'ชื่อแสดงผล',
                                  labelStyle: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  hintText: 'กรอกชื่อแสดงผลของคุณ',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(FontAwesomeIcons.solidUser, color: AppColors.textSecondary, size: 13),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.border, width: 1.5),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email Display Form (Minimalist Underline Style)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.border, width: 1.5),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12, bottom: 4),
                                      child: Icon(FontAwesomeIcons.solidEnvelope, color: AppColors.textSecondary, size: 13),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ที่อยู่อีเมลผู้ใช้ (ไม่สามารถแก้ไขได้)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _user.email ?? '',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'ยืนยันแล้ว',
                                          style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons Block
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ),
                            boxShadow: AppColors.primaryShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(FontAwesomeIcons.solidFloppyDisk, color: Colors.white, size: 16),
                                SizedBox(width: 10),
                                Text(
                                  'บันทึกข้อมูลการตั้งค่า',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton.icon(
                            onPressed: _logout,
                            icon: const Icon(FontAwesomeIcons.powerOff, color: AppColors.error, size: 15),
                            label: const Text(
                              'ออกจากระบบบัญชี',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.error.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(color: AppColors.error.withValues(alpha: 0.2), width: 1.5),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // System Branding Stamp
                        Text(
                          'EXAM SCANNER APP • VERSION 1.1.0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Icon(
                          FontAwesomeIcons.shieldHalved,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          size: 24,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: const Center(
                child: SpinKitCircle(color: AppColors.primary, size: 70.0),
              ),
            ),
        ],
      ),
    );
  }
}
