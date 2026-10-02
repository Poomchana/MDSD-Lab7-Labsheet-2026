import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ดึง API Key จากคำสั่ง --dart-define=GEMINI_API_KEY=your_key
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('AQ.Ab8RN6JOXlHQ_UJSG3lnImQTSmmD3KxJ_Z5Ku-xjTU0Ln4jLkA');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$_apiKey',
    );
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20)); // ตั้ง timeout 20 วินาที

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ตรวจสอบว่ามี candidates และ content ตอบกลับมาจริงหรือไม่
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw Exception('ไม่พบข้อมูลคำตอบจาก Gemini (candidates Is empty)');
        }
      } else {
        throw Exception(
          'เกิดข้อผิดพลาดจาก API: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
    }
  }
}
