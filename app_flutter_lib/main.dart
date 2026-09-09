import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

// TODO: replace with your real backend URL from Render (see Part C of the guide)
const String BACKEND_URL = "https://thanglish-tamil-vocie.onrender.com";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thanglish Tamil Voice',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String inputType = "thanglish"; // or "english"
  String voice = "female"; // or "male"
  String translatedText = "";
  String tamilText = "";
  String? audioUrl;
  bool loading = false;
  final AudioPlayer _player = AudioPlayer();

  Future<void> translateAndSpeak() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("$BACKEND_URL/process"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "input_type": inputType,
          "text": _controller.text,
          "voice": voice,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tamilText = data["tamil_text"];
          translatedText = data["translated_text"];
          audioUrl = "$BACKEND_URL${data["audio_url"]}";
          loading = false;
        });
      } else {
        setState(() => loading = false);
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => loading = false);
      _showError("Could not reach server. It may be waking up — try again in 20s.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> playAudio() async {
    if (audioUrl == null) return;
    await _player.setUrl(audioUrl!);
    _player.play();
  }

  Future<void> downloadAudio() async {
    if (audioUrl == null) return;
    final dir = await getExternalStorageDirectory();
    final savePath = "${dir!.path}/tamil_voice.mp3";
    await Dio().download(audioUrl!, savePath);
    _showError("Saved to: $savePath");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanglish ⇄ Tamil Voice")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Type Thanglish or English",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Thanglish"),
                    value: "thanglish",
                    groupValue: inputType,
                    onChanged: (v) => setState(() => inputType = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("English"),
                    value: "english",
                    groupValue: inputType,
                    onChanged: (v) => setState(() => inputType = v!),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("Male voice"),
                    value: voice == "male",
                    onChanged: (v) => setState(() => voice = v! ? "male" : "female"),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("Female voice"),
                    value: voice == "female",
                    onChanged: (v) => setState(() => voice = v! ? "female" : "male"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : translateAndSpeak,
              child: loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Translate & Generate Voice"),
            ),
            const SizedBox(height: 16),
            if (translatedText.isNotEmpty) ...[
              Text("Translated: $translatedText", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("Tamil: $tamilText", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: playAudio,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Play"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: downloadAudio,
                    icon: const Icon(Icons.download),
                    label: const Text("Download MP3"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
