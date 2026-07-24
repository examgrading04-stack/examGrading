import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _isCapturing = false;
  bool _hasCameraError = false;
  String _statusText = 'วางกระดาษคำตอบให้อยู่ในกรอบ \nแล้วกดปุ่มถ่ายภาพ';
  Color _statusColor = Colors.white;

  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

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
      _initializeCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initializeCamera([int? cameraIndex]) async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        throw CameraException('no_camera', 'ไม่พบกล้องบนอุปกรณ์นี้');
      }

      if (cameraIndex != null && cameraIndex < _availableCameras.length) {
        _selectedCameraIndex = cameraIndex;
      } else {
        final backIdx = _availableCameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backIdx != -1 ? backIdx : 0;
      }

      final selectedCamera = _availableCameras[_selectedCameraIndex];

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller?.dispose();

      _controller = controller;
      _initializeFuture = controller.initialize();
      await _initializeFuture;

      if (!mounted || !context.mounted) return;
      setState(() {
        _hasCameraError = false;
      });
    } catch (e) {
      if (!mounted || !context.mounted) return;
      setState(() {
        _hasCameraError = true;
        _statusText =
            'เปิดกล้องไม่ได้: $e\n(หากใช้กล้องอื่นอยู่ ให้ปิดแอพที่ใช้งานกล้องซ้อนกัน)';
        _statusColor = AppColors.error;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _initializeCamera(nextIndex);
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _statusText = 'กำลังถ่ายภาพ...';
      _statusColor = AppColors.success;
    });

    try {
      final image = await controller.takePicture();
      if (!mounted || !context.mounted) return;
      Navigator.pop(context, File(image.path));
    } catch (e) {
      if (!mounted || !context.mounted) return;
      setState(() {
        _isCapturing = false;
        _statusText = 'ถ่ายภาพไม่สำเร็จ กรุณาลองใหม่';
        _statusColor = AppColors.error;
      });
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
              CustomPaint(painter: _CameraMaskPainter(), size: Size.infinite),
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
                          if (_availableCameras.length > 1)
                            IconButton(
                              onPressed: _switchCamera,
                              icon: const Icon(
                                Icons.cameraswitch_outlined,
                                color: Colors.white,
                                size: 26,
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
                                      : Icons.camera_alt,
                                  color: _statusColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCapturing ? 'กำลังบันทึก' : 'โหมดชัตเตอร์',
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
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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

class _CameraMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.85;
    final frameHeight = math.min(size.height * 0.70, frameWidth * 1.42);
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2.2),
      width: frameWidth,
      height: frameHeight,
    );

    final overlayPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(24)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const cornerLength = 40.0;
    const inset = 2.0;

    void drawCorner(Offset corner, double xSign, double ySign) {
      final start = Offset(
        corner.dx + inset * xSign,
        corner.dy + inset * ySign,
      );
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
