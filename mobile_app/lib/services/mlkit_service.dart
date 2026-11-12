import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MLKitService {
  static TextRecognizer? _recognizer;

  static TextRecognizer get _instance {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  /// Check if on-device ML Kit OCR is supported (Android & iOS)
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Run Google ML Kit OCR on a local image file and return backend-compatible OCRResult structure
  static Future<Map<String, dynamic>> recognizeTextFromFile(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final recognizedText = await _instance.processImage(inputImage);

    final List<Map<String, dynamic>> linesList = [];
    double totalConfidence = 0.0;
    int lineCount = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        lineCount++;
        final bbox = [
          [line.boundingBox.left.toDouble(), line.boundingBox.top.toDouble()],
          [line.boundingBox.right.toDouble(), line.boundingBox.top.toDouble()],
          [line.boundingBox.right.toDouble(), line.boundingBox.bottom.toDouble()],
          [line.boundingBox.left.toDouble(), line.boundingBox.bottom.toDouble()],
        ];

        // TextLine confidence (defaults to 0.95 if null)
        double lineConf = line.confidence ?? 0.95;
        totalConfidence += lineConf;

        linesList.add({
          'text': line.text,
          'confidence': lineConf,
          'bbox': bbox,
        });
      }
    }

    final avgConf = lineCount > 0 ? (totalConfidence / lineCount) : 0.0;

    return {
      'raw_text': recognizedText.text,
      'lines': linesList,
      'page_count': 1,
      'average_confidence': avgConf,
    };
  }

  static Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
