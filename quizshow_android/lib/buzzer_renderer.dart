import 'package:flutter/material.dart';
import 'websocket_service.dart';

class BuzzerRenderer extends StatelessWidget {
  final WebSocketService webSocketService;
  final Map<String, dynamic> pageConfig;

  const BuzzerRenderer({
    super.key,
    required this.webSocketService,
    required this.pageConfig,
  });

  @override
  Widget build(BuildContext context) {
    final text = pageConfig['text'] ?? 'Buzzer';
            final _ = pageConfig['link']; // Unused but required for future use

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                // Send buzzer press to server
                webSocketService.sendBuzzerPress();
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red[400]!.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'BUZZER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
} 