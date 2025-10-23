import 'package:flutter/material.dart';
import 'dart:async';
import 'websocket_service.dart';

class TimerRenderer extends StatefulWidget {
  final WebSocketService webSocketService;
  final Map<String, dynamic> pageConfig;

  const TimerRenderer({
    super.key,
    required this.webSocketService,
    required this.pageConfig,
  });

  @override
  State<TimerRenderer> createState() => _TimerRendererState();
}

class _TimerRendererState extends State<TimerRenderer> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerFinished = false; // Used to track timer state

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(TimerRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we receive a new render command while timer is running, stop the timer
    if (oldWidget.pageConfig != widget.pageConfig && _timer != null) {
      _timer?.cancel();
      _timerFinished = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final timeSeconds = widget.pageConfig['time'] ?? 0;
    _remainingSeconds = timeSeconds;
    _timerFinished = false;

            if (_remainingSeconds > 0) {
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _remainingSeconds--;
              if (_remainingSeconds <= 0) {
                _timerFinished = true;
                timer.cancel();
                // Send timer finished message to server
                widget.webSocketService.sendTimerFinished();
              }
            });
          });
        } else {
          _timerFinished = true;
        }
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '0:00';
    
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '$remainingSeconds:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.pageConfig['text'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 40),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 