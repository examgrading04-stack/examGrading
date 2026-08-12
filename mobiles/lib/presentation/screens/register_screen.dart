import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/presentation/widgets/vector_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณากรอกข้อมูลให้ครบถ้วน',
        confirmBtnColor: const Color(0xFF2563EB),
      );
      return;
    }

    if (password != confirm) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'รหัสผ่านไม่ตรงกัน',
        confirmBtnColor: const Color(0xFF2563EB),
      );
      return;
    }

    if (password.length < 6) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
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

      await AuthService.instance.register(
        email,
        password,
        email.split('@').first,
      );

      if (!mounted || !context.mounted) return;
      Navigator.pop(context); // close loading
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'ลงทะเบียนสำเร็จ! กรุณาเข้าสู่ระบบ',
        confirmBtnColor: const Color(0xFF2563EB),
        onConfirmBtnTap: () {
          Navigator.pop(context); // close alert
          Navigator.pop(context); // back to login
        },
      );
    } on AuthException catch (e) {
      if (!mounted || !context.mounted) return;
      Navigator.pop(context);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: e.message,
        confirmBtnColor: const Color(0xFF2563EB),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      Navigator.pop(context);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: e.toString(),
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
            right: -100,
            child: _buildBlurCircle(300, const Color(0xFFE0F2FE)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurCircle(250, const Color(0xFFF0F9FF)),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 5),
                    // Branding Section
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const VectorLogo(size: 36),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'สร้างบัญชีใหม่',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'เริ่มต้นใช้งานระบบตรวจข้อสอบของคุณ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Register Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPremiumTextField(
                            controller: _emailController,
                            icon: Icons.alternate_email,
                            label: 'อีเมล',
                            hintText: 'name@example.com',
                          ),
                          const SizedBox(height: 10),
                          _buildPremiumTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            label: 'รหัสผ่าน',
                            hintText: 'อย่างน้อย 6 ตัวอักษร',
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildPremiumTextField(
                            controller: _confirmPasswordController,
                            icon: Icons.shield_outlined,
                            label: 'ยืนยันรหัสผ่าน',
                            hintText: 'กรอกรหัสผ่านอีกครั้ง',
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggle: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Register Button
                          GestureDetector(
                            onTap: _register,
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFF2563EB),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'สมัครสมาชิก',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Top Left Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
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
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
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
                vertical: 12,
                horizontal: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
