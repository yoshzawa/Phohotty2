import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleVisionService {
  final String apiKey;

  GoogleVisionService({required this.apiKey});

  Future<List<String>> analyzeLabels(Uint8List bytes) async {
    final base64Image = base64Encode(bytes);

    final url = Uri.parse(
      "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyCQmFMGebUKwKal5xqLrPd86mGgcwjCTjc",
    );

    final body = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "LABEL_DETECTION", "maxResults": 10}
          ]
        }
      ]
    };

    final response = await http
        .post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception("Vision API error: ${response.body}");
    }

    final result = jsonDecode(response.body);
    if (result["responses"] == null) {
      throw Exception("Invalid response: ${response.body}");
    }
    final labels = result["responses"][0]["labelAnnotations"];
    if (labels == null) return [];

    return labels.map<String>((e) => e["description"]).toList();
  }
}