import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractTextFromPath(String path) async {
    final inputImage = InputImage.fromFilePath(path);

    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    return recognizedText.text.trim();
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}