import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';

class FeedMessage {
  final String author;
  final String text;
  final IconData icon;

  FeedMessage({required this.author, required this.text, required this.icon});
}

class LiveFeedScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const LiveFeedScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends State<LiveFeedScreen> {
  final _messageController = TextEditingController();
  final List<FeedMessage> _messages = [
    FeedMessage(
      author: "Aarav Patel (Student Lead)",
      text: "14:15 - Sub-base gravel leveled. Compactor machine received from depot.",
      icon: Icons.engineering,
    ),
    FeedMessage(
      author: "Siddharth Mehta (Mentor)",
      text: "14:30 - Looks clean. Ensure ambient surface temperature is above 18°C.",
      icon: Icons.verified_user,
    ),
    FeedMessage(
      author: "Resource Allocation Bot",
      text: "15:02 - Micro-grant draw: \$42.00 dispatched for safety cones and markers.",
      icon: Icons.attach_money,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = ServiceLocator.instance.authManager;
    final mentorName = auth.currentProfile?.name ?? "Industry Mentor";

    setState(() {
      _messages.add(
        FeedMessage(
          author: "$mentorName (Mentor)",
          text: "${TimeOfDay.now().format(context)} - $text",
          icon: Icons.verified_user,
        ),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onNavigate(AppView.industrialistHome),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      "LIVE WORKSPACE • Mentorship Feed",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const Text(
                "Quality Index: 94/100 | Escrow Dispatched: \$420 Allocated",
                style: TextStyle(color: Color(0xFF059669), fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(msg.icon, color: const Color(0xFF006B4D)),
                  title: Text(
                    msg.author,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(msg.text, style: const TextStyle(fontSize: 12)),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Reply to team / send mentor guidance...",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Color(0xFF006B4D)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
