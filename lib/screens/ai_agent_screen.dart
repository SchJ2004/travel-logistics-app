import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// IMPORTANT: Make sure this import matches where your results screen is saved!
import 'flight_results_screen.dart'; 

class AiAgentScreen extends StatefulWidget {
  const AiAgentScreen({super.key});

  @override
  State<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends State<AiAgentScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': 'Hello! I am your AI travel concierge. Tell me where you want to go, or ask me to find a flight for a specific date!'
    }
  ];
  bool _isLoading = false;

  // --- THE NEURAL NET ENGINE ---
  // Drop your valid Gemini API key here
  static const String _apiKey = 'AIzaSyAgToFOdpMbW5xYNmsTF9r7Zaq3LNhUTas';
  
  final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
  );

  Future<void> _sendMessage() async {
    final userInput = _chatController.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': userInput});
      _isLoading = true;
    });
    
    _chatController.clear();

    // 1. Capture the exact date right now in YYYY-MM-DD format
    final today = DateTime.now().toIso8601String().split('T')[0];

    // 2. The Secret System Prompt: Now upgraded for Round-Trips!
    final systemPrompt = '''
You are a highly intelligent travel assistant built into a flight booking app. 

SYSTEM CONTEXT: Today's date is $today. Treat all relative dates (like 'tomorrow' or 'next friday') based on this current date.

Analyze the following user request: "$userInput"

If the user is asking to find or book a flight, extract the 3-letter airport code for the origin, the 3-letter airport code for the destination, and format the departure date STRICTLY as YYYY-MM-DD. 
If they ask for a round trip, extract the return date as YYYY-MM-DD as well. If it is a one-way trip, set return_date to null.

If it is a flight request, you MUST reply ONLY with this exact JSON structure and nothing else:
{"type": "flight_search", "origin": "XXX", "destination": "YYY", "date": "YYYY-MM-DD", "return_date": "YYYY-MM-DD" | null}

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
          String returnText = data['return_date'] != null ? ' and returning ${data['return_date']}' : '';
          _messages.add({
            'role': 'ai',
            'text': 'I found your route! Launching global grid for ${data['origin']} to ${data['destination']}$returnText...',
          });
          _isLoading = false;
        });

        // Add a slight delay for the Lottie animation, then auto-route to the Results Screen!
        await Future.delayed(const Duration(seconds: 2));
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
        // Header
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
        
        // Chat History
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
        
        // Loading Animation (The Lottie Airplane)
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_j1adxtyb.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const Text(
                  'Routing global grid...',
                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
          
        // Input Area
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
                    hintText: 'e.g., Get me out of JFK to LHR next Friday...',
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