import 'package:flutter/material.dart';
import 'websocket_service.dart';

class TextRenderer extends StatelessWidget {
  final WebSocketService webSocketService;
  final Map<String, dynamic> pageConfig;

  const TextRenderer({
    super.key,
    required this.webSocketService,
    required this.pageConfig,
  });

  @override
  Widget build(BuildContext context) {
    final header = pageConfig['header'] ?? 'Page';
    final text = pageConfig['text'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                header,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (text.isNotEmpty)
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 