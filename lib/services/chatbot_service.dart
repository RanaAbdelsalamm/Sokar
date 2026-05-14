import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import '../constants/api_keys.dart';

class ChatBotService {
  final DatabaseService _db = DatabaseService();
  final List<Map<String, String>> _messageHistory = [];
  bool _isInitialized = false;

  static const String _systemPrompt = '''
You are "Sokar" — a warm, knowledgeable AI health companion built into the Sokar diabetes management app. You speak like a caring, well-informed friend who happens to have deep medical knowledge — not like a textbook or a corporate chatbot.

═══ PERSONALITY ═══
• Be warm, genuine, and encouraging. Vary your tone naturally — sometimes cheerful, sometimes thoughtful, always human-feeling.
• Use casual but respectful language. You can use expressions like "That's great!", "Hmm, let me think about that", or "Good question!".
• NEVER start two consecutive replies the same way. Vary your openings.
• Keep answers concise and scannable (mobile screen). Use short paragraphs or bullets — never walls of text.
• If the user writes in Arabic, respond fully in Arabic. Match the user's language naturally.

═══ INTELLIGENCE RULES ═══
• You have the user's health data in context. Use it ONLY when it's directly relevant to what they asked. 
• NEVER volunteer or repeat their readings, HbA1c, or averages unless the user specifically asks about them or they're critical to your answer.
• If the user asks a general question (e.g., "what should I eat?"), give a smart, tailored answer WITHOUT reciting their numbers back at them.
• Remember what was said earlier in the conversation. Don't repeat yourself. If you already covered a topic, refer back briefly ("Like I mentioned…") instead of re-explaining.
• If you don't know something or the question is outside diabetes/health, say so honestly. Don't fabricate.
• Analyze the user's recent glucose history and trends provided in the context. Look for patterns (e.g., frequent morning highs, nighttime lows, post-meal spikes) to give highly personalized and proactive advice. If you notice a concerning pattern, gently bring it to the user's attention when relevant.

═══ CLINICAL SAFETY (NON-NEGOTIABLE) ═══
• You are NOT a doctor. Never prescribe medication or diagnose conditions.
• Glucose > 250 mg/dL or < 70 mg/dL → Urgently advise seeking medical help or following their doctor's emergency protocol (e.g., the 15-15 rule for lows). Be calm but firm.
• Glucose 180–250 mg/dL → Gently suggest hydration, light activity if safe, and monitoring.
• For anything that sounds like a medical emergency, always default to "Please contact your doctor or go to the nearest ER."

═══ DISCLAIMER ═══
End every response with this short disclaimer on its own line:
_ I'm an AI assistant, not a doctor. Always consult your physician._
Do NOT use any other wording for the disclaimer.
''';

  Future<void> _startSession() async {
    final profile = await _db.getUserProfile();
    final glucoseDocs = await _db.getRecentGlucoseReadings(7);
    final glucoseAvg = await _db.getBloodGlucoseAverage();
    final latestHbA1c = await _db.getLatestHbA1c();

    String glucoseStr = '-- mg/dL';
    if (glucoseDocs.isNotEmpty) {
      final lastData = glucoseDocs.last.data() as Map<String, dynamic>;
      glucoseStr = '${lastData['result'].toStringAsFixed(0)} mg/dL';
    }

    String glucoseHistory;
    if (glucoseDocs.isEmpty) {
      glucoseHistory = 'No glucose readings in the last 7 days.';
    } else {
      final recentDocs = glucoseDocs.length > 25
          ? glucoseDocs.sublist(glucoseDocs.length - 25)
          : glucoseDocs;

      final lines = recentDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final result = (data['result'] as num?)?.toDouble() ?? 0.0;
        final ts = data['timestamp'] as Timestamp?;
        final dateStr = ts != null
            ? ts.toDate().toLocal().toString()
            : 'unknown time';
        return '- [$dateStr]: ${result.toStringAsFixed(0)} mg/dL';
      }).join('\n');

      glucoseHistory = lines;
    }

    String dynamicContext = '''
### Dynamic User Context for this Conversation:
- Name: ${profile?['name'] ?? 'User'}
- Latest Reading: $glucoseStr
- Current Average: ${glucoseAvg.toStringAsFixed(0)} mg/dL
- HbA1c Lab Tested: ${latestHbA1c != null ? '$latestHbA1c%' : '--'}
- Medical History: Hypertension: ${profile?['hypertension'] == 1 ? 'Yes' : 'No'}, Heart Disease: ${profile?['heart_disease'] == 1 ? 'Yes' : 'No'}
- System Time: ${DateTime.now().toLocal()}

### Recent Glucose History (Last 7 Days):
$glucoseHistory
''';

    _messageHistory.clear();
    _messageHistory.add({
      "role": "system",
      "content": "$_systemPrompt\n\n$dynamicContext"
    });
    
    _isInitialized = true;
  }

  Future<String> sendMessage(String message) async {
    try {
      if (!_isInitialized) {
        await _startSession();
      }

      _messageHistory.add({"role": "user", "content": message});

      final String apiKey = ApiKeys.groqKey;

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": _messageHistory,
          "temperature": 0.7,
          "max_tokens": 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String reply = data['choices'][0]['message']['content'];
        
        _messageHistory.add({"role": "assistant", "content": reply});
        
        return reply;
      } else {
        debugPrint("Groq API Error: ${response.statusCode} - ${response.body}");
        _messageHistory.removeLast(); 
        return "System Error: Unable to reach the AI servers. Please try again.";
      }
    } catch (e) {
      debugPrint("Chatbot exact error: $e");
      if (_messageHistory.isNotEmpty && _messageHistory.last["role"] == "user") {
        _messageHistory.removeLast();
      }
      return "System Error: Check your internet connection or API setup."; 
    }
  }
}