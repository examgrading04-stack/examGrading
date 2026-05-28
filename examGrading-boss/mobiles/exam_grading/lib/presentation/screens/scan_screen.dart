import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
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
import 'package:exam_grading/presentation/theme/app_colors.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

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

  Future<void> _openAutoScanner() async {
    final scannedImage = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (context) => const AnswerSheetCameraScreen()),
    );

    if (scannedImage != null && mounted) {
      setState(() {
        _image = scannedImage;
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
      const Duration(seconds: 60),
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

  Future<void> _warmupServer() async {
    try {
      await http
          .get(ApiConfig.endpoint('/api/health'))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Ignore warmup failures; real request will surface actionable errors.
    }
  }

  Future<void> _uploadAndProcess() async {
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
      // 1. Upload to Cloudinary
      final cloudUrl = await uploadToCloudinary(_image!);
      if (cloudUrl == null) {
        throw Exception('อัปโหลดรูปล้มเหลว (Cloudinary)');
      }

      final uid = FirebaseAuth.instance.currentUser!.email!;

      // 2. Call FastAPI (warmup + retry for cold start hosting)
      await _warmupServer();

      Future<http.Response> sendScanRequest() {
        return http
            .post(
              ApiConfig.endpoint('/api/scan-cloudinary'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'image_url': cloudUrl,
                'user_email': uid,
              }),
            )
            .timeout(
              const Duration(seconds: 90),
              onTimeout: () => throw Exception(
                'หมดเวลาเชื่อมต่อ Server: ${ApiConfig.baseUrl}',
              ),
            );
      }

      http.Response response;
      try {
        response = await sendScanRequest();
      } on Exception {
        response = await sendScanRequest();
      }

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'สแกนสำเร็จ! ได้ ${result['score']} / ${result['total']} คะแนน',
          confirmBtnColor: AppColors.primary,
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
              'เพิ่มกระดาษคำตอบ',
              style: TextStyle(
                fontSize: 22,
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
                  label: 'สแกนอัตโนมัติ',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _openAutoScanner();
                  },
                ),
                _buildPickerOption(
                  icon: FontAwesomeIcons.solidImage,
                  label: 'อัลบั้มภาพ',
                  color: const Color(0xFF7C3AED), // Keep violet secondary
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
              background: Container(
                color: AppColors.surface,
              ),
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

                  GestureDetector(
                    onTap: _showPickerBottomSheet,
                    child: Container(
                      height: 380,
                      decoration: BoxDecoration(
                        color: _image != null
                            ? Colors.black
                            : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: _image == null
                            ? Border.all(
                                color: AppColors.border,
                                width: 2,
                              )
                            : null,
                        boxShadow: [
                          if (_image != null)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          if (_image == null)
                            ...AppColors.softShadow,
                        ],
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_image!, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
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
                                          color: Colors.black.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
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
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      FontAwesomeIcons.camera,
                                      size: 28,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'แตะเพื่อสแกนหรือเลือกภาพ',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ระบบจะอ่านรหัสข้อสอบจาก QR บนกระดาษคำตอบ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
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
                      borderRadius: BorderRadius.circular(18),
                      color: _image == null ? AppColors.border : AppColors.primary,
                      boxShadow: [
                        if (_image != null)
                          ...AppColors.primaryShadow,
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
                                color: _image == null ? AppColors.textMuted : Colors.white,
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

class AnswerSheetCameraScreen extends StatefulWidget {
  const AnswerSheetCameraScreen({Key? key}) : super(key: key);

  @override
  State<AnswerSheetCameraScreen> createState() =>
      _AnswerSheetCameraScreenState();
}

class _AnswerSheetCameraScreenState extends State<AnswerSheetCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  double? _lastLuma;
  DateTime? _stableSince;
  DateTime _lastFrameCheck = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isCapturing = false;
  bool _isStreaming = false;
  bool _hasCameraError = false;
  String _statusText = 'วางกระดาษคำตอบให้อยู่ในกรอบ';
  Color _statusColor = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'ไม่พบกล้องบนอุปกรณ์นี้');
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _controller = controller;
      _initializeFuture = controller.initialize();
      await _initializeFuture;

      if (!mounted) return;
      setState(() {});
      await _startAutoScan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasCameraError = true;
        _statusText = 'เปิดกล้องไม่ได้: $e';
        _statusColor = AppColors.error;
      });
    }
  }

  Future<void> _startAutoScan() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    _isStreaming = true;
    await controller.startImageStream(_handleCameraImage);
  }

  void _handleCameraImage(CameraImage image) {
    if (_isCapturing || !mounted) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameCheck).inMilliseconds < 240) return;
    _lastFrameCheck = now;

    final luma = _sampleLuma(image.planes.first.bytes);
    final lastLuma = _lastLuma;
    _lastLuma = luma;

    if (luma < 55) {
      _markUnstable('เพิ่มแสงอีกนิด');
      return;
    }

    if (lastLuma == null || (luma - lastLuma).abs() > 7) {
      _markUnstable('ถือให้นิ่งในกรอบ');
      return;
    }

    _stableSince ??= now;
    final stableMs = now.difference(_stableSince!).inMilliseconds;
    if (stableMs > 1100) {
      _captureAutomatically();
      return;
    }

    _updateStatus('กำลังจับภาพอัตโนมัติ...', AppColors.success);
  }

  double _sampleLuma(Uint8List bytes) {
    if (bytes.isEmpty) return 0;
    final step = math.max(1, bytes.length ~/ 900);
    var total = 0;
    var count = 0;

    for (var i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      count++;
    }

    return total / count;
  }

  void _markUnstable(String message) {
    _stableSince = null;
    _updateStatus(message, Colors.white);
  }

  void _updateStatus(String message, Color color) {
    if (_statusText == message && _statusColor == color) return;
    setState(() {
      _statusText = message;
      _statusColor = color;
    });
  }

  Future<void> _captureAutomatically() async {
    final controller = _controller;
    if (controller == null || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _statusText = 'กำลังสแกน...';
      _statusColor = AppColors.success;
    });

    try {
      if (_isStreaming && controller.value.isStreamingImages) {
        await controller.stopImageStream();
        _isStreaming = false;
      }

      final image = await controller.takePicture();
      if (!mounted) return;
      Navigator.pop(context, File(image.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _stableSince = null;
        _statusText = 'สแกนไม่สำเร็จ ลองจัดกระดาษใหม่';
        _statusColor = AppColors.error;
      });
      await _startAutoScan();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (_hasCameraError) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.no_photography_outlined,
                      color: Colors.white,
                      size: 54,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            );
          }

          if (controller == null ||
              snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: SpinKitThreeBounce(color: Colors.white, size: 24),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraPreview(controller),
              CustomPaint(
                painter: _AnswerSheetMaskPainter(),
                size: Size.infinite,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isCapturing
                                      ? Icons.document_scanner
                                      : Icons.center_focus_strong,
                                  color: _statusColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCapturing ? 'Auto scan' : 'Auto',
                                  style: TextStyle(
                                    color: _statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isCapturing)
                Container(
                  color: Colors.black.withValues(alpha: 0.18),
                  child: const Center(
                    child: SpinKitPulse(color: Colors.white, size: 80),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return Center(child: CameraPreview(controller));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenRatio = constraints.maxWidth / constraints.maxHeight;
        final previewRatio = previewSize.height / previewSize.width;
        final scale = math.max(
          screenRatio / previewRatio,
          previewRatio / screenRatio,
        );

        return Transform.scale(
          scale: scale,
          child: Center(child: CameraPreview(controller)),
        );
      },
    );
  }
}

class _AnswerSheetMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.82;
    final frameHeight = math.min(size.height * 0.66, frameWidth * 1.42);
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameWidth,
      height: frameHeight,
    );

    final overlayPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.54),
    );

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(24)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const cornerLength = 44.0;
    const inset = 2.0;

    void drawCorner(Offset corner, double xSign, double ySign) {
      final start = Offset(corner.dx + inset * xSign, corner.dy + inset * ySign);
      canvas.drawLine(
        start,
        start + Offset(cornerLength * xSign, 0),
        cornerPaint,
      );
      canvas.drawLine(
        start,
        start + Offset(0, cornerLength * ySign),
        cornerPaint,
      );
    }

    drawCorner(frame.topLeft, 1, 1);
    drawCorner(frame.topRight, -1, 1);
    drawCorner(frame.bottomLeft, 1, -1);
    drawCorner(frame.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
