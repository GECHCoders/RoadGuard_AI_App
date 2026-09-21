import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


void main() {
  runApp(const RoadGuardApp());
}

class RoadGuardApp extends StatelessWidget {
  const RoadGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoadGuard AI',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050811),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
        ),
      ),
      home: const RoadGuardHome(),
    );
  }
}

class RoadGuardHome extends StatefulWidget {
  const RoadGuardHome({super.key});

  @override
  State<RoadGuardHome> createState() => _RoadGuardHomeState();
}

class _RoadGuardHomeState extends State<RoadGuardHome>
    with SingleTickerProviderStateMixin {
  Position? currentPosition;
  bool loadingLocation = false;
  String locationMessage = 'Location not detected';

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;

      CameraDescription camera = cameras.first;
      for (final item in cameras) {
        if (item.lensDirection == CameraLensDirection.back) {
          camera = item;
          break;
        }
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(camera: camera),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      loadingLocation = true;
      locationMessage = 'Locating...';
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          locationMessage = 'Turn on GPS to locate';
          loadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          locationMessage = 'Location permission unavailable';
          loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        currentPosition = position;
        locationMessage =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
        loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        locationMessage = 'Unable to get location';
        loadingLocation = false;
      });
    }
  }

  Widget _glass(Widget child, {
    EdgeInsets padding = const EdgeInsets.all(18),
    double radius = 22,
    Color? color,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF0D1524).withValues(alpha: .86),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: .075),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: _glass(
        Column(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 21),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        radius: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050811),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF38BDF8),
                              Color(0xFF2563EB),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ROADGUARD',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'AI ROAD INTELLIGENCE',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _OnlinePill(pulse: _pulse),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'SMARTER ROADS.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SAFER\nJOURNEYS.',
                    style: TextStyle(
                      fontSize: 41,
                      height: .96,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI-powered road hazard detection for the roads you travel every day.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 22),

                  _glass(
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI VISION ENGINE',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .8,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'ON-DEVICE • READY TO SCAN',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF22C55E),
                              size: 21,
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: .06),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.radar_rounded,
                              color: Color(0xFF38BDF8),
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            const Expanded(
                              child: Text(
                                'Detect potholes & road cracks in real time',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              'TFLITE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .3),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _openCamera,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8),
                              foregroundColor: const Color(0xFF04111C),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(19),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 27),
                                SizedBox(width: 8),
                                Text(
                                  'START ROAD SCAN',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(17),
                    radius: 26,
                    color: const Color(0xFF0A1625),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _stat('00', 'HAZARDS', Icons.warning_amber_rounded),
                      const SizedBox(width: 9),
                      _stat('0.0', 'KM SCANNED', Icons.route_rounded),
                      const SizedBox(width: 9),
                      _stat('--', 'SAFETY', Icons.shield_outlined),
                    ],
                  ),

                  const SizedBox(height: 26),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'LIVE ROAD MAP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: getCurrentLocation,
                        icon: const Icon(Icons.my_location_rounded, size: 15),
                        label: const Text('LOCATE'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          textStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  _glass(
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 240,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: currentPosition == null
                                    ? const LatLng(12.9716, 77.5946)
                                    : LatLng(
                                        currentPosition!.latitude,
                                        currentPosition!.longitude,
                                      ),
                                initialZoom: 13,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.roadguard_ai',
                                ),
                                const RichAttributionWidget(
                                  attributions: [
                                    TextSourceAttribution(
                                      'OpenStreetMap contributors',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: _glass(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFF38BDF8),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      loadingLocation
                                          ? 'LOCATING...'
                                          : locationMessage,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                radius: 12,
                                color: const Color(0xFF07101A)
                                    .withValues(alpha: .9),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: _glass(
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.radar_rounded,
                                      color: Color(0xFF38BDF8),
                                      size: 16,
                                    ),
                                    SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        'Road hazard intelligence layer',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white38,
                                      size: 18,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                radius: 14,
                                color: const Color(0xFF07101A)
                                    .withValues(alpha: .9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    radius: 24,
                  ),

                  const SizedBox(height: 24),

                  _glass(
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF22C55E)
                                .withValues(alpha: .1),
                          ),
                          child: const Icon(
                            Icons.public_rounded,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR SCAN MATTERS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .8,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Turn everyday road observations into useful safety intelligence.',
                                style: TextStyle(

                                  fontSize: 10,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: Text(
                      'ROADGUARD AI  •  BUILDING SAFER ROADS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .22),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  final Animation<double> pulse;

  const _OnlinePill({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1524),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E)
                          .withValues(alpha: .25 + pulse.value * .35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ONLINE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Detection {
  final String label;
  final double confidence;

  // Values are normalized from 0.0 to 1.0.
  final double left;
  final double top;
  final double right;
  final double bottom;

  Detection({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

// ======================================================
// CAMERA + AI
// ======================================================



class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const int modelSize = 640;
  static const List<String> labels = [
    'Crocodile Crack',
    'Longitudinal Crack',
    'Pothole',
  ];
  static const double confidenceThreshold = 0.35;
  static const double iouThreshold = 0.45;

late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  Interpreter? _interpreter;

  String _modelStatus = 'Loading AI model...';
  String _detectionStatus = 'Waiting for camera frame...';

  List<Detection> _detections = [];

  bool _isProcessingFrame = false;
  DateTime _lastInference =
  DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    _loadModel();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _initializeControllerFuture =
        _initializeCamera();
  }

  // ----------------------------------------------------
  // CAMERA INITIALIZATION
  // ----------------------------------------------------

  Future<void> _initializeCamera() async {
    await _controller.initialize();

    if (!mounted) return;

    await _controller.startImageStream(
      _processCameraImage,
    );
  }

  // ----------------------------------------------------
  // LOAD TFLITE
  // ----------------------------------------------------

  Future<void> _loadModel() async {
    try {
      final Interpreter interpreter =
      await Interpreter.fromAsset(
        'assets/models/best.tflite',
      );

      if (!mounted) {
        interpreter.close();
        return;
      }

      _interpreter = interpreter;

      final inputShape =
          interpreter.getInputTensor(0).shape;

      final outputShape =
          interpreter.getOutputTensor(0).shape;

      debugPrint(
        '==========================================',
      );
      debugPrint(
        '✅ RoadGuard AI model loaded successfully!',
      );
      debugPrint('Input shape: $inputShape');
      debugPrint('Output shape: $outputShape');
      debugPrint(
        '==========================================',
      );

      setState(() {
        _modelStatus = 'AI Model Loaded ✅';
      });
    } catch (e) {
      debugPrint(
        '❌ Model loading failed: $e',
      );

      if (!mounted) return;

      setState(() {
        _modelStatus = 'AI Model Failed ❌';
      });
    }
  }

  // ----------------------------------------------------
  // CAMERA FRAME PROCESSING
  // ----------------------------------------------------

  Future<void> _processCameraImage(
      CameraImage cameraImage,
      ) async {
    if (_interpreter == null) {
      return;
    }

    if (_isProcessingFrame) {
      return;
    }

    // Do not run inference on every camera frame.
    // This keeps the emulator/device responsive.
    final now = DateTime.now();

    if (now.difference(_lastInference).inMilliseconds <
        700) {
      return;
    }

    _lastInference = now;
    _isProcessingFrame = true;

    try {
      final img.Image? rgbImage =
      _convertCameraImage(cameraImage);

      if (rgbImage == null) {
        return;
      }

      final img.Image resized =
      img.copyResize(
        rgbImage,
        width: modelSize,
        height: modelSize,
        interpolation: img.Interpolation.linear,
      );

      final Float32List input =
      _imageToInput(resized);

      final List<double> output =
      List<double>.filled(
        7 * 8400,
        0.0,
      );

      _interpreter!.run(
        input,
        output,
      );

      final detections =
      _parseYoloOutput(output);

      if (!mounted) return;

      setState(() {
        _detections = detections;

        if (detections.isEmpty) {
          _detectionStatus =
          'Scanning road... No hazard detected';
        } else {
          final first = detections.first;

          _detectionStatus =
          '${detections.length} hazard(s): '
              '${first.label} '
              '${(first.confidence * 100).toStringAsFixed(0)}%';
        }
      });
    } catch (e) {
      debugPrint(
        'Inference error: $e',
      );

      if (mounted) {
        setState(() {
          _detectionStatus =
          'AI inference error';
        });
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ----------------------------------------------------
  // YUV420 CAMERA -> RGB IMAGE
  // ----------------------------------------------------

  img.Image? _convertCameraImage(
      CameraImage cameraImage,
      ) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      if (cameraImage.planes.length < 3) {
        return null;
      }

      final planeY = cameraImage.planes[0];
      final planeU = cameraImage.planes[1];
      final planeV = cameraImage.planes[2];

      final img.Image output =
      img.Image(
        width: width,
        height: height,
      );

      final int yRowStride =
          planeY.bytesPerRow;

      final int uRowStride =
          planeU.bytesPerRow;

      final int vRowStride =
          planeV.bytesPerRow;

      final int uPixelStride =
          planeU.bytesPerPixel ?? 1;

      final int vPixelStride =
          planeV.bytesPerPixel ?? 1;

      for (int y = 0; y < height; y++) {
        final int yRow =
            y * yRowStride;

        final int uvRow =
            (y >> 1) * uRowStride;

        final int vvRow =
            (y >> 1) * vRowStride;

        for (int x = 0; x < width; x++) {
          final int yIndex =
              yRow + x;

          final int uvIndex =
              uvRow +
                  (x >> 1) * uPixelStride;

          final int vvIndex =
              vvRow +
                  (x >> 1) * vPixelStride;

          final int yValue =
          planeY.bytes[yIndex];

          final int uValue =
          planeU.bytes[uvIndex];

          final int vValue =
          planeV.bytes[vvIndex];

          final double r =
              yValue +
                  1.402 * (vValue - 128);

          final double g =
              yValue -
                  0.344136 * (uValue - 128) -
                  0.714136 * (vValue - 128);

          final double b =
              yValue +
                  1.772 * (uValue - 128);

          final int red =
          r.round().clamp(0, 255);

          final int green =
          g.round().clamp(0, 255);

          final int blue =
          b.round().clamp(0, 255);

          output.setPixel(
            x,
            y,
            img.ColorRgb8(
              red,
              green,
              blue,
            ),
          );
        }
      }

      return output;
    } catch (e) {
      debugPrint(
        'Image conversion error: $e',
      );
      return null;
    }
  }

  // ----------------------------------------------------
  // IMAGE -> FLOAT32 MODEL INPUT
  // ----------------------------------------------------

  Float32List _imageToInput(
      img.Image image,
      ) {
    final Float32List input =
    Float32List(
      modelSize *
          modelSize *
          3,
    );

    int index = 0;

    for (int y = 0; y < modelSize; y++) {
      for (int x = 0; x < modelSize; x++) {
        final pixel =
        image.getPixel(x, y);

        // YOLO exported float32 models normally
        // expect RGB values normalized to 0..1.
        input[index++] =
            pixel.r / 255.0;

        input[index++] =
            pixel.g / 255.0;

        input[index++] =
            pixel.b / 255.0;
      }
    }

    return input;
  }

  // ----------------------------------------------------
  // YOLO OUTPUT PARSER
  // ----------------------------------------------------

  List<Detection> _parseYoloOutput(
      List<double> output,
      ) {

    const int candidates = 8400;

    final List<_RawDetection> raw =
    [];

    for (int i = 0; i < candidates; i++) {
      final double x =
      output[i];

      final double y =
      output[candidates + i];

      final double w =
      output[(2 * candidates) + i];

      final double h =
      output[(3 * candidates) + i];

      final double class0 =
      output[(4 * candidates) + i];

      final double class1 =
      output[(5 * candidates) + i];

      final double class2 =
      output[(6 * candidates) + i];

      final List<double> scores = [
        class0,
        class1,
        class2,
      ];

      int bestClass = 0;
      double bestScore = scores[0];

      for (int c = 1; c < scores.length; c++) {
        if (scores[c] > bestScore) {
          bestScore = scores[c];
          bestClass = c;
        }
      }

      if (bestScore < confidenceThreshold) {
        continue;
      }

      // YOLO output is x-center, y-center, width, height.
      final double left =
          (x - w / 2) / modelSize;

      final double top =
          (y - h / 2) / modelSize;

      final double right =
          (x + w / 2) / modelSize;

      final double bottom =
          (y + h / 2) / modelSize;

      raw.add(
        _RawDetection(
          classIndex: bestClass,
          confidence: bestScore,
          left: left.clamp(0.0, 1.0),
          top: top.clamp(0.0, 1.0),
          right: right.clamp(0.0, 1.0),
          bottom: bottom.clamp(0.0, 1.0),
        ),
      );
    }

    final List<_RawDetection> selected =
    _nms(raw);

    return selected
        .map(
          (d) => Detection(
        label: labels[d.classIndex],
        confidence: d.confidence,
        left: d.left,
        top: d.top,
        right: d.right,
        bottom: d.bottom,
      ),
    )
        .toList();
  }

  // ----------------------------------------------------
  // NON-MAXIMUM SUPPRESSION
  // ----------------------------------------------------

  List<_RawDetection> _nms(
      List<_RawDetection> detections,
      ) {
    final List<_RawDetection> sorted =
    List<_RawDetection>.from(
      detections,
    );

    sorted.sort(
          (a, b) =>
          b.confidence.compareTo(
            a.confidence,
          ),
    );

    final List<_RawDetection> selected =
    [];

    while (sorted.isNotEmpty) {
      final current =
      sorted.removeAt(0);

      selected.add(current);

      sorted.removeWhere(
            (other) {
          if (other.classIndex !=
              current.classIndex) {
            return false;
          }

          return _iou(
            current,
            other,
          ) >
              iouThreshold;
        },
      );

      if (selected.length >= 20) {
        break;
      }
    }

    return selected;
  }

  double _iou(
      _RawDetection a,
      _RawDetection b,
      ) {
    final double left =
    math.max(
      a.left,
      b.left,
    );

    final double top =
    math.max(
      a.top,
      b.top,
    );

    final double right =
    math.min(
      a.right,
      b.right,
    );

    final double bottom =
    math.min(
      a.bottom,
      b.bottom,
    );

    final double intersectionWidth =
    math.max(
      0.0,
      right - left,
    );

    final double intersectionHeight =
    math.max(
      0.0,
      bottom - top,
    );

    final double intersection =
        intersectionWidth *
            intersectionHeight;

    final double areaA =
        math.max(
          0.0,
          a.right - a.left,
        ) *
            math.max(
              0.0,
              a.bottom - a.top,
            );

    final double areaB =
        math.max(
          0.0,
          b.right - b.left,
        ) *
            math.max(
              0.0,
              b.bottom - b.top,
            );

    final double union =
        areaA +
            areaB -
            intersection;

    if (union <= 0) {
      return 0;
    }

    return intersection / union;
  }

  @override
  void dispose() {
    try {
      if (_controller.value.isStreamingImages) {
        _controller.stopImageStream();
      }
    } catch (_) {}

    _controller.dispose();
    _interpreter?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasHazard = _detections.isNotEmpty;
    final primary = hasHazard ? _detections.first : null;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ColoredBox(
              color: Color(0xFF05080D),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF38BDF8),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Text(
                  'Unable to start camera',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller),

              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: DetectionPainter(detections: _detections),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 180,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: topInset + 12,
                left: 15,
                right: 15,
                child: Row(
                  children: [
                    _hudButton(
                      Icons.arrow_back_rounded,
                      () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _hudPill(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _LiveDot(),
                            const SizedBox(width: 7),
                            const Text(
                              'ROAD SCAN  •  LIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    _hudButton(Icons.flash_auto_rounded, () {}),
                  ],
                ),
              ),

              Positioned(
                top: topInset + 72,
                left: 15,
                right: 15,
                child: Row(
                  children: [
                    Expanded(
                      child: _hudPill(
                        Row(
                          children: [
                            const Icon(
                              Icons.memory_rounded,
                              color: Color(0xFF38BDF8),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _modelStatus,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _hudPill(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.gps_fixed_rounded,
                            color: Color(0xFF22C55E),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'GPS LIVE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 235,
                    height: 235,
                    child: CustomPaint(
                      painter: _ScanReticlePainter(active: !hasHazard),
                    ),
                  ),
                ),
              ),

              if (primary != null)
                Positioned(
                  left: 18,
                  right: 18,
                  top: MediaQuery.of(context).size.height * .53,
                  child: _hazardCard(primary),
                ),

              Positioned(
                left: 15,
                right: 15,
                bottom: bottomInset + 18,
                child: Column(
                  children: [
                    _hudPill(
                      Row(
                        children: [
                          Icon(
                            hasHazard
                                ? Icons.warning_amber_rounded
                                : Icons.radar_rounded,
                            color: hasHazard
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF38BDF8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasHazard
                                  ? '${_detections.length} ROAD HAZARD DETECTED'
                                  : 'AI IS SCANNING THE ROAD...',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                              ),
                            ),
                          ),
                          Text(
                            hasHazard ? 'ALERT' : 'ACTIVE',
                            style: TextStyle(
                              color: hasHazard
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF22C55E),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _metric(Icons.center_focus_strong_rounded,
                              '${_detections.length}', 'DETECTIONS'),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _metric(Icons.auto_awesome_rounded,
                              'AI', 'VISION'),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _metric(Icons.location_on_rounded,
                              'LIVE', 'GPS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hudPill(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .64),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: .12),
        ),
      ),
      child: child,
    );
  }

  Widget _hudButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .64),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: .12),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return _hudPill(
      Column(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 15),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hazardCard(Detection detection) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F17).withValues(alpha: .93),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: .6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: .12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: .11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HAZARD DETECTED',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detection.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(detection.confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF22C55E),
      ),
    );
  }
}

class _ScanReticlePainter extends CustomPainter {
  final bool active;

  _ScanReticlePainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: active ? .78 : .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1;

    const c = 25.0;
    const p = 8.0;
    final r = size.width - p;
    final b = size.height - p;

    canvas.drawLine(const Offset(p, p), const Offset(p + c, p), paint);
    canvas.drawLine(const Offset(p, p), const Offset(p, p + c), paint);
    canvas.drawLine(Offset(r, p), Offset(r - c, p), paint);
    canvas.drawLine(Offset(r, p), Offset(r, p + c), paint);
    canvas.drawLine(Offset(p, b), Offset(p + c, b), paint);
    canvas.drawLine(Offset(p, b), Offset(p, b - c), paint);
    canvas.drawLine(Offset(r, b), Offset(r - c, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r, b - c), paint);

    final center = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: .45)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2 - 16, size.height / 2),
      Offset(size.width / 2 + 16, size.height / 2),
      center,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2 - 16),
      Offset(size.width / 2, size.height / 2 + 16),
      center,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanReticlePainter oldDelegate) =>
      oldDelegate.active != active;
}

// ======================================================
// RAW DETECTION
// ======================================================

class _RawDetection {
  final int classIndex;
  final double confidence;
  final double left;
  final double top;
  final double right;
  final double bottom;

  _RawDetection({
    required this.classIndex,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

// ======================================================
// DETECTION PAINTER
// ======================================================

class DetectionPainter
    extends CustomPainter {
  final List<Detection> detections;

  DetectionPainter({
    required this.detections,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final Paint boxPaint =
    Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint backgroundPaint =
    Paint()
      ..color = Colors.redAccent.withValues(
        alpha: 0.85,
      );

    for (final detection in detections) {
      final double left =
          detection.left * size.width;

      final double top =
          detection.top * size.height;

      final double right =
          detection.right * size.width;

      final double bottom =
          detection.bottom * size.height;

      final Rect rect =
      Rect.fromLTRB(
        left,
        top,
        right,
        bottom,
      );

      canvas.drawRect(
        rect,
        boxPaint,
      );

      final String text =
          '${detection.label} '
          '${(detection.confidence * 100).toStringAsFixed(0)}%';

      final TextPainter textPainter =
      TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection:
        TextDirection.ltr,
      );

      textPainter.layout();

      final double labelWidth =
          textPainter.width + 10;

      final double labelHeight =
          textPainter.height + 6;

      final double labelTop =
      math.max(
        0,
        top - labelHeight,
      );

      canvas.drawRect(
        Rect.fromLTWH(
          left,
          labelTop,
          labelWidth,
          labelHeight,
        ),
        backgroundPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          left + 5,
          labelTop + 3,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant DetectionPainter oldDelegate,
      ) {
    return oldDelegate.detections !=
        detections;
  }
}
