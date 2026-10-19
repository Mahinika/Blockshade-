import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen error reporter for device screenshots when startup fails.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.message,
    this.title = 'Blockshade kunde inte starta',
  });

  final String message;
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF2B1D14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3B2A1E),
          title: Text(title, style: const TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kopiera texten nedan och skicka till support:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feltext kopierad')),
                    );
                  },
                  child: const Text('Kopiera feltext'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
