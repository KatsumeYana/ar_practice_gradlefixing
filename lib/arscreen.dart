import 'dart:typed_data';

import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'gif_frame_extractor.dart';
import 'animated_texture_manager.dart';

class ARPaintingWithAnimatedGifScreen extends StatefulWidget {
  const ARPaintingWithAnimatedGifScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ARPaintingWithAnimatedGifScreenState createState() =>
      _ARPaintingWithAnimatedGifScreenState();
}

class _ARPaintingWithAnimatedGifScreenState
    extends State<ARPaintingWithAnimatedGifScreen> {
  late ArCoreController arCoreController;
  late AnimatedTextureManager textureManager;

  String? _currentNodeName;
  vector.Vector3? _nodePosition;
  vector.Vector4? _nodeRotation;
  vector.Vector3? _nodeScale;

  List<Uint8List> gifFrames = [];
  bool isLoading = true;
  bool _objectPlaced = false;

  @override
  void initState() {
    super.initState();
    _loadGifFrames();
  }

  Future<void> _loadGifFrames() async {
    try {
      gifFrames = await GifFrameExtractor.extractGifFrames('assets/kurukuru-kururing.gif');

      if (gifFrames.isNotEmpty) {
        setState(() {
          isLoading = false;
        });
      } else {
        _showError('Failed to load GIF frames');
      }
    } catch (e) {
      _showError('Error loading GIF: $e');
    }
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController.onPlaneDetected = _onPlaneDetected;
  }

  void _onPlaneDetected(ArCorePlane plane) {
    print('Plane detected - Type: ${plane.type}, Position: ${plane.centerPose}');
    if (!_objectPlaced && plane.type == ArCorePlaneType.VERTICAL) {
      print('Vertical plane detected! Adding painting...');
      _addAnimatedPainting(plane);
      setState(() {
        _objectPlaced = true;
      });
    } else if (plane.type != ArCorePlaneType.VERTICAL) {
      print('Detected plane is not vertical (type: ${plane.type})');
    }
  }

  void _addAnimatedPainting(ArCorePlane plane) {
    final planePose = plane.centerPose;
    if (planePose == null) return;
    _nodePosition = vector.Vector3(planePose.translation.x, planePose.translation.y, planePose.translation.z);
    _nodeRotation = vector.Vector4(planePose.rotation.x, planePose.rotation.y, planePose.rotation.z, planePose.rotation.w);
    _nodeScale = vector.Vector3(0.5, 0.5, 0.5);
    _currentNodeName = 'animated_painting_${DateTime.now().millisecondsSinceEpoch}';

    final material = ArCoreMaterial(
      color: Colors.white,
      textureBytes: gifFrames[0],
    );

    final cube = ArCoreCube(
      materials: [material],
      size: _nodeScale!,
    );

    final node = ArCoreNode(
      shape: cube,
      position: _nodePosition!,
      rotation: _nodeRotation!,
      name: _currentNodeName,
    );

    arCoreController.addArCoreNode(node);

    _initializeTextureAnimation();
  }

  void _initializeTextureAnimation() {
    if (_currentNodeName == null || gifFrames.isEmpty) return;

    textureManager = AnimatedTextureManager(
      frames: gifFrames,
      frameRateMs: 100,
      onFrameUpdate: (Uint8List frameData) {
        _updateNodeTexture(frameData);
      },
    );

    textureManager.startAnimation();
  }

  void _updateNodeTexture(Uint8List frameData) {
    if (_currentNodeName == null ||
        _nodePosition == null ||
        _nodeRotation == null ||
        _nodeScale == null) {
      return;
    }

    arCoreController.removeNode(nodeName: _currentNodeName!);

    final updatedMaterial = ArCoreMaterial(
      color: Colors.white,
      textureBytes: frameData,
    );

    final cube = ArCoreCube(
      materials: [updatedMaterial],
      size: _nodeScale!,
    );

    final newNode = ArCoreNode(
      shape: cube,
      position: _nodePosition!,
      rotation: _nodeRotation!,
      name: _currentNodeName,
    );

    arCoreController.addArCoreNode(newNode);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Animated GIF Texture'),
        actions: [
          if (!isLoading)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'pause') {
                  textureManager.pauseAnimation();
                } else if (value == 'resume') {
                  textureManager.resumeAnimation();
                } else if (value == 'stop') {
                  textureManager.stopAnimation();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'pause',
                  child: Text('Pause Animation'),
                ),
                const PopupMenuItem(
                  value: 'resume',
                  child: Text('Resume Animation'),
                ),
                const PopupMenuItem(
                  value: 'stop',
                  child: Text('Stop Animation'),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading GIF frames...'),
                ],
              ),
            )
          : Stack(
              children: [
                ArCoreView(
                  onArCoreViewCreated: _onArCoreViewCreated,
                  enableUpdateListener: true,
                ),
                if (!_objectPlaced)
                  const Center(
                    child: Text(
                      'Move your phone to detect a wall',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    textureManager.dispose();
    arCoreController.dispose();
    super.dispose();
  }
}