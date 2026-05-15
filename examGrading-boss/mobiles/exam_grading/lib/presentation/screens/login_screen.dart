import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:exam_grading/presentation/screens/dashboard_screen.dart';
import 'package:exam_grading/presentation/screens/register_screen.dart';
import 'package:exam_grading/presentation/widgets/vector_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณากรอกอีเมลและรหัสผ่าน',
        confirmBtnColor: const Color(0xFF2563EB),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: SpinKitCircle(color: Colors.white, size: 70.0)),
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      Navigator.pop(context); // ปิด loading
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // ปิด loading
      String msg = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        msg = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'invalid-email') {
        msg = 'รูปแบบอีเมลไม่ถูกต้อง';
      }
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: msg,
        confirmBtnColor: const Color(0xFF2563EB),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: e.toString(),
        confirmBtnColor: const Color(0xFF2563EB),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: SpinKitCircle(color: Colors.white, size: 70.0)),
      );

      // บังคับให้ลบ Session เก่าออกก่อน เพื่อให้หน้าต่างเลือก Email เด้งขึ้นมาทุกครั้ง
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      Navigator.pop(context); // close loading
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Google Sign-In failed: $e',
        confirmBtnColor: const Color(0xFF2563EB),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _usernameController.text.trim();
    if (email.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณากรอกอีเมลในช่องด้านบนเพื่อรีเซ็ตรหัสผ่าน',
        confirmBtnColor: const Color(0xFF2563EB),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text:
            'ส่งอีเมลรีเซ็ตรหัสผ่านเรียบร้อยแล้ว กรุณาตรวจสอบกล่องจดหมายของคุณ',
        confirmBtnColor: const Color(0xFF2563EB),
      );
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'ไม่พบอีเมลนี้ในระบบหรือเกิดข้อผิดพลาด',
        confirmBtnColor: const Color(0xFF2563EB),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Aesthetic
          Container(decoration: const BoxDecoration(color: Color(0xFFF8FAFC))),
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlurCircle(300, const Color(0xFFDBEAFE)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildBlurCircle(250, const Color(0xFFEFF6FF)),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: _buildBlurCircle(200, const Color(0xFFF1F5F9)),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 5),
                    // Branding Section
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const VectorLogo(size: 36),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'EXAM GRADING',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Login Card (Glassmorphism inspired but clean)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ยินดีต้อนรับกลับ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Email
                          _buildPremiumTextField(
                            controller: _usernameController,
                            icon: Icons.alternate_email,
                            label: 'อีเมลผู้ใช้งาน',
                            hintText: 'name@example.com',
                          ),
                          const SizedBox(height: 12),

                          // Password
                          _buildPremiumTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            label: 'รหัสผ่าน',
                            hintText: '••••••••',
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'ลืมรหัสผ่าน?',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Login Button
                          GestureDetector(
                            onTap: _login,
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1D4ED8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Divider for Social Login
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: const Color(0xFFE2E8F0)),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'หรือ',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: const Color(0xFFE2E8F0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Google Login Button
                          GestureDetector(
                            onTap: _signInWithGoogle,
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    FontAwesomeIcons.google,
                                    color: Color(0xFFEA4335),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'ลงชื่อเข้าใช้ด้วย Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ยังไม่มีบัญชี? ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text(
                            'สร้างบัญชีใหม่',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hintText,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? (obscureText ?? true) : false,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        (obscureText ?? true)
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      onPressed: onToggle,
                    )
                  : null,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
