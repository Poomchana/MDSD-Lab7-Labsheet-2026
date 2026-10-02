import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  Future<ListingDraft> analyzeProductImage(File imageFile) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    
    // ดึง API Key จากสภาพแวดล้อม หรือใช้ Key สำรองในการทดสอบ
    final activeKey = apiKey.isNotEmpty 
        ? apiKey 
        : 'AQ.Ab8RN6JOXlHQ_UJSG3lnImQTSmmD3KxJ_Z5Ku-xjTU0Ln4jLkA';

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final mimeType = imageFile.path.endsWith('.png') ? 'image/png' : 'image/jpeg';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$activeKey',
    );

    // Prompt สำหรับการวิเคราะห์สินค้าตามปกติ
    const promptText = '''
วิเคราะห์ภาพสินค้านี้ และตอบกลับในรูปแบบ JSON โดยมีฟิลด์ดังนี้:
- title: ชื่อสินค้าที่น่าสนใจ ความยาวไม่เกิน 50 ตัวอักษร
- category: หมวดหมู่สินค้า (เช่น เสื้อผ้า, ไอที, ของใช้, หนังสือ ฯลฯ)
- description: คำอธิบายรายละเอียดสินค้า ความยาวประมาณ 2-3 ประโยค
''';

    final body = {
      "contents": [
        {
          "parts": [
            {"text": promptText},
            {
              "inline_data": {"mime_type": mimeType, "data": base64Image},
            },
          ],
        },
      ],
      "generationConfig": {
        "response_mime_type": "application/json",
        "response_schema": {
          "type": "OBJECT",
          "properties": {
            "title": {"type": "STRING"},
            "category": {"type": "STRING"},
            "description": {"type": "STRING"},
          },
          "required": ["title", "category", "description"],
        },
      },
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final candidates = jsonResponse['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้ กรุณาลองใหม่อีกครั้ง');
      }

      final firstCandidate = candidates[0];
      if (firstCandidate['finishReason'] == 'SAFETY') {
        throw Exception('เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น');
      }

      final parts = firstCandidate['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('ไม่พบผลลัพธ์จาก AI กรุณาลองใหม่อีกครั้ง');
      }

      final textResult = parts[0]['text'];
      final Map<String, dynamic> parsedJson = jsonDecode(textResult);

      return ListingDraft.fromJson(parsedJson);
    } else {
      throw Exception('เกิดข้อผิดพลาดจาก Gemini API: ${response.statusCode} - ${response.body}');
    }
  }
}