import 'package:flutter/material.dart';
import 'websocket_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class MasterScreen extends StatefulWidget {
  final WebSocketService webSocketService;

  const MasterScreen({
    super.key,
    required this.webSocketService,
  });

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  Map<String, dynamic> _pointsData = {
    'team_red': 0,
    'team_blue': 0,
    'team_yellow': 0,
    'team_green': 0,
    'enabled_team': 'team_red',
    'last_buzzer_team': null,
    'team_red_devices': 0,
    'team_blue_devices': 0,
    'team_yellow_devices': 0,
    'team_green_devices': 0,
  };
  Timer? _pointsTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start fetching points after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startPointsTimer();
      }
    });
  }

  @override
  void dispose() {
    _pointsTimer?.cancel();
    super.dispose();
  }

  void _startPointsTimer() {
    if (!widget.webSocketService.isConnected) return;
    
    _fetchPoints();
    _pointsTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && widget.webSocketService.isConnected) {
        _fetchPoints();
      }
    });
  }

  Future<void> _fetchPoints() async {
    if (!widget.webSocketService.isConnected || !mounted) return;
    
    try {
      final serverUrl = widget.webSocketService.lastServerUrl ?? '192.168.178.149';
      // Extract just the IP address from the WebSocket URL
      final ipAddress = serverUrl.replaceAll(RegExp(r'^ws://|^http://'), '').split(':')[0];
      final response = await http.get(
        Uri.parse('http://$ipAddress:8080/points'),
      ).timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _pointsData = Map<String, dynamic>.from(data);
        });
      }
    } catch (e) {
      // Silently handle errors to avoid spam
      if (mounted) {
        debugPrint('Failed to fetch points: $e');
      }
    }
  }

  void _sendNextSlide() {
    widget.webSocketService.sendNextSlide();
  }

  void _sendReturnToMain() {
    widget.webSocketService.sendReturnToMain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header with navigation buttons
            Row(
              children: [
                Expanded(
                  child: _buildNavigationButton(
                    'Next Slide',
                    Colors.green,
                    _sendNextSlide,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNavigationButton(
                    'Return to Main',
                    Colors.orange,
                    _sendReturnToMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Team points and connected devices - 2x2 grid
            Expanded(
              child: Column(
                children: [
                  // First row - Team Red and Team Blue
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Team Red',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_red']} points',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_red_devices']} devices',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8, bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Team Blue',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_blue']} points',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_blue_devices']} devices',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Second row - Team Yellow and Team Green
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, top: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.yellow, width: 2),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Team Yellow',
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_yellow']} points',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_yellow_devices']} devices',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8, top: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Team Green',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_green']} points',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_pointsData['team_green_devices']} devices',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Status displays
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Enabled Team',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _pointsData['enabled_team'] == 'team_red' ? 'Team Red' : 
                          _pointsData['enabled_team'] == 'team_blue' ? 'Team Blue' :
                          _pointsData['enabled_team'] == 'team_yellow' ? 'Team Yellow' :
                          _pointsData['enabled_team'] == 'team_green' ? 'Team Green' : 'None',
                          style: TextStyle(
                            color: _pointsData['enabled_team'] == 'team_red' ? Colors.red : 
                                   _pointsData['enabled_team'] == 'team_blue' ? Colors.blue :
                                   _pointsData['enabled_team'] == 'team_yellow' ? Colors.yellow :
                                   _pointsData['enabled_team'] == 'team_green' ? Colors.green : Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Last Buzzer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _pointsData['last_buzzer_team'] ?? 'None',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Control buttons
            Expanded(
              child: Column(
                children: [
                  // Add Points row
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildControlButton(
                            'Add Red',
                            Colors.red,
                            () => widget.webSocketService.sendMasterAddPoints('team_red', 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Add Blue',
                            Colors.blue,
                            () => widget.webSocketService.sendMasterAddPoints('team_blue', 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Add Yellow',
                            Colors.yellow,
                            () => widget.webSocketService.sendMasterAddPoints('team_yellow', 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Add Green',
                            Colors.green,
                            () => widget.webSocketService.sendMasterAddPoints('team_green', 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Remove Points row
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildControlButton(
                            'Remove Red',
                            Colors.red[700]!,
                            () => widget.webSocketService.sendMasterRemovePoints('team_red', 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Remove Blue',
                            Colors.blue[700]!,
                            () => widget.webSocketService.sendMasterRemovePoints('team_blue', 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Remove Yellow',
                            Colors.yellow[700]!,
                            () => widget.webSocketService.sendMasterRemovePoints('team_yellow', 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Remove Green',
                            Colors.green[700]!,
                            () => widget.webSocketService.sendMasterRemovePoints('team_green', 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Enable Teams row
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildControlButton(
                            'Enable Red',
                            Colors.red,
                            () => widget.webSocketService.sendMasterEnableTeam('team_red'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Enable Blue',
                            Colors.blue,
                            () => widget.webSocketService.sendMasterEnableTeam('team_blue'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Enable Yellow',
                            Colors.yellow,
                            () => widget.webSocketService.sendMasterEnableTeam('team_yellow'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Enable Green',
                            Colors.green,
                            () => widget.webSocketService.sendMasterEnableTeam('team_green'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Reset and Disable All row
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildControlButton(
                            'Reset All',
                            Colors.orange,
                            () => widget.webSocketService.sendMasterReset(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildControlButton(
                            'Disable All',
                            Colors.grey,
                            () => widget.webSocketService.sendMasterEnableTeam('none'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildNavigationButton(String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        // Add tap effect
        setState(() {
          _isLoading = true;
        });
        onPressed();
        // Reset loading state after a short delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isLoading ? color.withOpacity(0.6) : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        // Add tap effect
        setState(() {
          _isLoading = true;
        });
        onPressed();
        // Reset loading state after a short delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isLoading ? color.withOpacity(0.6) : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
} 