import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/design_tokens.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'ai',
      'text': "Hello! I'm PayNora AI. How can I help you move money today? Try asking:\n• 'Send ₦1,000,000 to John in London'\n• 'What is my current balance?'"
    }
  ];
  bool _loading = false;

  Future<void> _sendMessage([String? text]) async {
    final query = text ?? _promptController.text;
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query.trim()});
      _loading = true;
    });
    if (text == null) _promptController.clear();

    try {
      final res = await _api.chatAI(query.trim());
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': res['message'],
          'action': res['proposed_action'],
        });
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': "Couldn't reach the AI engine right now. Please try again."
        });
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayNoraColors.surface,
      appBar: AppBar(
        title: const Text('✨ PayNora AI Assistant', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: PayNoraColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Suggested prompt chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip("Send ₦1,000,000 to John in London"),
                _chip("What is my balance?"),
                _chip("What is the NGN to GBP rate?"),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? PayNoraColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser ? null : Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (m['action'] != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('STRUCTURED INTENT', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
                                Text('Send ${m['action']['source_amount']} ${m['action']['source_currency']} to ${m['action']['recipient_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('AI is thinking...', style: TextStyle(color: Colors.black45, fontSize: 12)),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    onSubmitted: (t) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask PayNora AI anything...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: PayNoraColors.primary),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: PayNoraColors.primary)),
        backgroundColor: const Color(0xFFEDE9FE),
        onPressed: () => _sendMessage(text),
      ),
    );
  }
}
