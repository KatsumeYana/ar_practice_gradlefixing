import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class GifFrameExtractor {
  /// Extracts all frames from an animated GIF file
  /// Returns a list of Uint8List representing each frame as PNG bytes
  static Future<List<Uint8List>> extractGifFrames(String assetPath) async {
    try {
      // Load the GIF file from assets
      final ByteData data = await rootBundle.load(assetPath);
      
      // Create a codec to decode the GIF
      final ui.Codec codec = 
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      
      // Get the total number of frames
      final int frameCount = codec.frameCount;
      print('Total frames in GIF: $frameCount');
      
      // List to store extracted frames
      final List<Uint8List> frames = <Uint8List>[];
      
      // Extract each frame
      for (int i = 0; i < frameCount; i++) {
        // Get the next frame from the codec
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        
        // Convert the frame image to PNG bytes
        final Uint8List? frameBytes = 
            await _imageToBytes(frameInfo.image);
        
        if (frameBytes != null) {
          frames.add(frameBytes);
          print('Extracted frame ${i + 1}/$frameCount');
        }
      }
      
      print('Successfully extracted ${frames.length} frames');
      return frames;
    } catch (e) {
      print('Error extracting GIF frames: $e');
      return [];
    }
  }
  
  /// Converts a ui.Image to Uint8List (PNG format)
  static Future<Uint8List?> _imageToBytes(ui.Image image) async {
    try {
      final ByteData? byteData = 
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error converting image to bytes: $e');
      return null;
    }
  }
  
  /// Extracts GIF frames from a network URL
  static Future<List<Uint8List>> extractGifFramesFromNetwork(String url) async {
    try {
      final ByteData data = 
          await NetworkAssetBundle(Uri.parse(url)).load(url);
      
      final ui.Codec codec = 
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      
      final int frameCount = codec.frameCount;
      final List<Uint8List> frames = <Uint8List>[];
      
      for (int i = 0; i < frameCount; i++) {
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final Uint8List? frameBytes = 
            await _imageToBytes(frameInfo.image);
        
        if (frameBytes != null) {
          frames.add(frameBytes);
        }
      }
      
      return frames;
    } catch (e) {
      print('Error extracting GIF from network: $e');
      return [];
    }
  }
}