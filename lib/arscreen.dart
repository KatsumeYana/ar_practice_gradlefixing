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
  
  // Store node information
  String? _currentNodeName;
  vector.Vector3? _nodePosition;
  vector.Vector4? _nodeRotation;
  vector.Vector3? _nodeScale;
  
  List<Uint8List> gifFrames = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifFrames();
  }

  /// Loads GIF frames from assets
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

  /// Callback when ARCore view is created
  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController.onPlaneTap = _handleOnPlaneTap;
  }

  /// Handles tap on detected plane
  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty || gifFrames.isEmpty) return;
    
    final hit = hits.first;
    _addAnimatedPainting(hit);
  }

  /// Adds a painting with animated GIF texture
  void _addAnimatedPainting(ArCoreHitTestResult hit) {
    // Store node information for re-adding
    _nodePosition = hit.pose.translation;
    _nodeRotation = hit.pose.rotation;
    _nodeScale = vector.Vector3(0.5, 0.5, 0.5);
    _currentNodeName = 'animated_painting_${DateTime.now().millisecondsSinceEpoch}';

    // 3d cube placeholder for the painting
    // Create the material with the first frame
    final material = ArCoreMaterial(
      color: Colors.white,
      textureBytes: gifFrames[0],
    );

    // Create the 3D shape (cube)
    final cube = ArCoreCube(
      materials: [material],
      size: _nodeScale!,
    );

    // Create the node
    final node = ArCoreNode(
      shape: cube,
      position: _nodePosition!,
      rotation: _nodeRotation!,
      name: _currentNodeName,
    );

    // Add the node to the scene
    arCoreController.addArCoreNodeWithAnchor(node);

    // Initialize the texture manager
    _initializeTextureAnimation();
  }

  /// Initializes the texture animation
  void _initializeTextureAnimation() {
    if (_currentNodeName == null || gifFrames.isEmpty) return;

    // Create the texture manager
    textureManager = AnimatedTextureManager(
      frames: gifFrames,
      frameRateMs: 100,
      onFrameUpdate: (Uint8List frameData) {
        _updateNodeTexture(frameData);
      },
    );

    textureManager.startAnimation();
  }

  /// Updates the node's texture by removing and re-adding it
  void _updateNodeTexture(Uint8List frameData) {
    if (_currentNodeName == null || 
        _nodePosition == null || 
        _nodeRotation == null ||
        _nodeScale == null) {
      return;
    }

    // Remove the old node
    arCoreController.removeNode(nodeName: _currentNodeName!);

    // Create a new material with the updated texture
    final updatedMaterial = ArCoreMaterial(
      color: Colors.white,
      textureBytes: frameData,
    );

    // Create a new shape with the updated material
    final cube = ArCoreCube(
      materials: [updatedMaterial],
      size: _nodeScale!,
    );

    // Create a new node with the same position and rotation
    final newNode = ArCoreNode(
      shape: cube,
      position: _nodePosition!,
      rotation: _nodeRotation!,
      name: _currentNodeName,
    );

    // Add the new node
    arCoreController.addArCoreNodeWithAnchor(newNode);
  }

  /// Shows error message
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
          : ArCoreView(
              onArCoreViewCreated: _onArCoreViewCreated,
              enableTapRecognizer: true,
            ),
      floatingActionButton: isLoading
          ? null
          : FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tap on a plane to place the animated painting'),
                  ),
                );
              },
              child: const Icon(Icons.info),
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