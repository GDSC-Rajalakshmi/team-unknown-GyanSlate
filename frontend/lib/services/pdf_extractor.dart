import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFExtractor {
  Future<List<String>> extractFromPDF(Uint8List pdfData) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfData);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String text = extractor.extractText();
      document.dispose();
      
      return _parseContent(text);
    } catch (e) {
      throw Exception('Failed to extract PDF content: $e');
    }
  }

  List<String> _parseContent(String content) {
    List<String> topics = [];
    List<String> lines = content.split('\n');
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty || line.length < 4) continue;
      
      // Basic filtering to avoid headers, footers, and page numbers
      if (!RegExp(r'^\d+$').hasMatch(line) && // Skip pure numbers
          !line.toLowerCase().contains('page') && // Skip page indicators
          !line.toLowerCase().contains('header') && // Skip headers
          !line.toLowerCase().contains('footer')) { // Skip footers
        topics.add(line);
      }
    }
    
    return topics;
  }
} 