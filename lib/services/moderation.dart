import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:street_buddy/models/toxicity.dart';

/// A class for performing moderation checks on text and image content.
class Moderation {
  static const texturl =
      "https://toxicityapi.netlify.app/.netlify/functions/toxicity";
  static const imgurl = "https://nudenetapi-production.up.railway.app/detect";

/// Checks the text content for potential toxicity using a remote API.
  ///
  /// This method sends the provided [text] to a remote toxicity detection API and
  /// returns a [Toxicity] object if the text is considered toxic, or `null` if
  /// the text is not toxic or the API request fails.
  ///
  /// The method uses the `texturl` constant to construct the API endpoint URL and
  /// sends the text in the request body as a JSON-encoded object.
  ///
  /// If the API response has a status code of 200 (OK), the method decodes the
  /// response body and returns a `Toxicity` object created from the response
  /// data. Otherwise, it returns `null`.
  ///
  /// Callers should handle the case where `null` is returned, as it indicates
  /// that the text was not detected as toxic or the API request failed for some
  /// reason.
///

  static Future<Toxicity?> checkText(String text) async {
    final response = await http.post(
      Uri.parse(texturl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({"text": text}),
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Toxicity.fromJson(data);
    }
    return null;
  }

/// Checks the text content for potential toxicity using a remote API.
  static Future<bool> checkTextbool(String text) async {
    final response = await http.post(
      Uri.parse(texturl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({"text": text}),
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data.toString().contains('true');
    }
    return false;
  }

/// Checks the image content for potential nudity using a remote API.
  static Future<bool> checkImg(String url) async {
    final response = await http.post(
      Uri.parse(imgurl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({"image_url": url}),
    );
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data.toString().contains('EXPOSED');
    }
    return false;
  }
}

/// A widget that allows users to test the moderation functionality.
class TestModeration extends StatefulWidget {
  const TestModeration({super.key});

  @override
  State<TestModeration> createState() => TestModerationState();
}

class TestModerationState extends State<TestModeration> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Text Moderation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Enter text to moderate"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                var check = await Moderation.checkTextbool(_controller.text);
                print(check);
              },
              child: const Text("Moderate"),
            ),
          ],
        ),
      ),
    );
  }
}
