import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'flight_results_screen.dart';

class AIAgentScreen extends StatefulWidget {
  const AIAgentScreen({super.key});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Waking up the Gemini Model
  // ---> PASTE YOUR API KEY HERE <---
  final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyBLvq1rV0DPxhbEXP8xBMYHG_gChWNNfOM', 
  );

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'Hello! I am your AI travel concierge. Tell me where you want to go, or ask me to find a flight for a specific date!',
    });
  }

  Future<void> _sendMessage() async {
    final userInput = _chatController.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': userInput});
      _isLoading = true;
    });
    
    _chatController.clear();

    // The Secret System Prompt: This tells the AI how to act and format data
    final systemPrompt = '''
You are a highly intelligent travel assistant built into a flight booking app. 
Analyze the following user request: "$userInput"

If the user is asking to find or book a flight, extract the 3-letter airport code for the origin, the 3-letter airport code for the destination, and format the date as M/D/YYYY (assume the current year is 2026 if not specified). 
If it is a flight request, you MUST reply ONLY with this exact JSON structure and nothing else:
{"type": "flight_search", "origin": "XXX", "destination": "YYY", "date": "M/D/YYYY"}

If the user is just asking a general travel question, making a joke, or asking for recommendations, answer normally in plain text as a friendly travel agent.
''';

    try {
      final response = await _model.generateContent([Content.text(systemPrompt)]);
      final responseText = response.text?.trim() ?? '';

      // Check if the AI returned our secret JSON trigger
      if (responseText.contains('"type": "flight_search"')) {
        // Clean up formatting in case the AI added markdown blocks
        final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final data = jsonDecode(cleanJson);

        setState(() {
          _messages.add({
            'role': 'ai',
            'text': 'I found your route! Launching the global aviation grid for ${data['origin']} to ${data['destination']}...',
          });
          _isLoading = false;
        });

        // Add a slight delay for user experience, then auto-route to the Results Screen!
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlightResultsScreen(
                origin: data['origin'],
                destination: data['destination'],
                date: data['date'],
              ),
            ),
          );
        }
      } else {
        // If it wasn't a flight search, just show the AI's normal text response
        setState(() {
          _messages.add({'role': 'ai', 'text': responseText});
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'System Error: Connection to neural net severed. ($e)'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: const Color(0xFF1E293B),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Concierge', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Powered by Gemini', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blueAccent : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                      bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                  ),
                  child: Text(msg['text']!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.blueAccent),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., Get me out of JFK to LHR on 10/24/2026...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
