import 'dart:async';
import 'dart:typed_data';

class AnimatedTextureManager {
  final List<Uint8List> frames;
  late final int frameRateMs; // Milliseconds between frames
  late Timer _animationTimer;
  int _currentFrameIndex = 0;
  bool _isAnimating = false;
  
  // Callback to update the texture
  final Function(Uint8List frameData) onFrameUpdate;
  
  AnimatedTextureManager({
    required this.frames,
    required this.onFrameUpdate,
    this.frameRateMs = 100, // Default 100ms per frame (10 FPS)
  }) {
    if (frames.isEmpty) {
      throw Exception('Frames list cannot be empty');
    }
  }
  
  /// Starts the animation loop
  void startAnimation() {
    if (_isAnimating) return;
    
    _isAnimating = true;
    _currentFrameIndex = 0;
    
    // Send the first frame immediately
    onFrameUpdate(frames[_currentFrameIndex]);
    
    // Create a timer to update frames
    _animationTimer = Timer.periodic(
      Duration(milliseconds: frameRateMs),
      (_) {
        _currentFrameIndex = (_currentFrameIndex + 1) % frames.length;
        onFrameUpdate(frames[_currentFrameIndex]);
      },
    );
    
    print('Animation started with ${frames.length} frames');
  }
  
  /// Stops the animation loop
  void stopAnimation() {
    if (!_isAnimating) return;
    
    _animationTimer.cancel();
    _isAnimating = false;
    print('Animation stopped');
  }
  
  /// Pauses the animation
  void pauseAnimation() {
    if (!_isAnimating) return;
    _animationTimer.cancel();
    _isAnimating = false;
  }
  
  /// Resumes the animation
  void resumeAnimation() {
    if (_isAnimating) return;
    startAnimation();
  }
  
  /// Sets the frame rate (in milliseconds)
  void setFrameRate(int ms) {
    final wasAnimating = _isAnimating;
    if (wasAnimating) stopAnimation();
    
    frameRateMs = ms;
    
    if (wasAnimating) startAnimation();
  }
  
  /// Gets the current frame index
  int getCurrentFrameIndex() => _currentFrameIndex;
  
  /// Gets the total number of frames
  int getFrameCount() => frames.length;
  
  /// Cleans up resources
  void dispose() {
    stopAnimation();
  }
}