import 'package:flutter/material.dart';
import 'websocket_service.dart';
import 'grid_renderer.dart';
import 'buzzer_renderer.dart';
import 'text_renderer.dart';
import 'timer_renderer.dart';
import 'image_renderer.dart';
import 'master_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final TextEditingController _ipController = TextEditingController();
  bool _isConnecting = false;
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('last_server_ip');
      if (savedIp != null && savedIp.isNotEmpty) {
        _ipController.text = savedIp;
      }
    } catch (e) {
      // Silently handle errors
      debugPrint('Failed to load saved IP: $e');
    }
  }

  Future<void> _saveIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_server_ip', ip);
    } catch (e) {
      // Silently handle errors
      debugPrint('Failed to save IP: $e');
    }
  }



  Future<void> _connectToServer(String mode) async {
    if (_ipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an IP address')),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // Connect to WebSocket server
      final serverUrl = 'http://${_ipController.text}';
      final success = await _webSocketService.connect(serverUrl, mode);
      
      if (success && mounted) {
        // Save the IP address on successful connection
        await _saveIp(_ipController.text);
        
        // Navigate to the specific screen based on mode
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _getScreenForMode(mode),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to server')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Widget _getScreenForMode(String mode) {
    switch (mode) {
      case 'team_red':
        return TeamRedScreen(webSocketService: _webSocketService);
      case 'team_blue':
        return TeamBlueScreen(webSocketService: _webSocketService);
      case 'team_yellow':
        return TeamYellowScreen(webSocketService: _webSocketService);
      case 'team_green':
        return TeamGreenScreen(webSocketService: _webSocketService);
      case 'master':
        return MasterScreenWrapper(webSocketService: _webSocketService);
      default:
        return const MainMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // IP Input Field
            Container(
              width: double.infinity,
              height: 80,
              margin: const EdgeInsets.only(bottom: 20),
              child: TextField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Enter Server IP Address',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
            // Buttons Grid
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
                            child: ElevatedButton(
                              onPressed: _isConnecting ? null : () => _connectToServer('team_red'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isConnecting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'TEAM RED',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8, bottom: 8),
                            child: ElevatedButton(
                              onPressed: _isConnecting ? null : () => _connectToServer('team_blue'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isConnecting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'TEAM BLUE',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            child: ElevatedButton(
                              onPressed: _isConnecting ? null : () => _connectToServer('team_yellow'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isConnecting
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text(
                                      'TEAM YELLOW',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8, bottom: 8),
                            child: ElevatedButton(
                              onPressed: _isConnecting ? null : () => _connectToServer('team_green'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isConnecting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'TEAM GREEN',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Third row - Master Button (spans full width)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: _isConnecting ? null : () => _connectToServer('master'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConnecting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'MASTER',
                                style: TextStyle(
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    // Don't dispose the WebSocket service when navigating to new screens
    // It will be disposed when the app is actually closed
    super.dispose();
  }
}

// Placeholder screens for each mode
class TeamRedScreen extends StatelessWidget {
  final WebSocketService webSocketService;
  
  const TeamRedScreen({super.key, required this.webSocketService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: webSocketService,
        builder: (context, child) {
          final config = webSocketService.config;
          final currentPage = webSocketService.currentPage;
          
          if (config.isEmpty) {
            return const Center(
              child: Text(
                'Loading config...',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          final pageConfig = config[currentPage];
          if (pageConfig == null) {
            return const Center(
              child: Text(
                'Page not found',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          if (pageConfig['type'] == 'main') {
            return GridRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'buzzer') {
            return BuzzerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'text') {
            return TextRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'timer') {
            return TimerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'image') {
            return ImageRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          // For other page types, show a simple text display
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pageConfig['header'] ?? 'Page $currentPage',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  pageConfig['text'] ?? 'No content',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TeamBlueScreen extends StatelessWidget {
  final WebSocketService webSocketService;
  
  const TeamBlueScreen({super.key, required this.webSocketService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: webSocketService,
        builder: (context, child) {
          final config = webSocketService.config;
          final currentPage = webSocketService.currentPage;
          
          if (config.isEmpty) {
            return const Center(
              child: Text(
                'Loading config...',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          final pageConfig = config[currentPage];
          if (pageConfig == null) {
            return const Center(
              child: Text(
                'Page not found',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          if (pageConfig['type'] == 'main') {
            return GridRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'buzzer') {
            return BuzzerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'text') {
            return TextRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'timer') {
            return TimerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'image') {
            return ImageRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          // For other page types, show a simple text display
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pageConfig['header'] ?? 'Page $currentPage',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  pageConfig['text'] ?? 'No content',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TeamYellowScreen extends StatelessWidget {
  final WebSocketService webSocketService;
  
  const TeamYellowScreen({super.key, required this.webSocketService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: webSocketService,
        builder: (context, child) {
          final config = webSocketService.config;
          final currentPage = webSocketService.currentPage;
          
          if (config.isEmpty) {
            return const Center(
              child: Text(
                'Loading config...',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          final pageConfig = config[currentPage];
          if (pageConfig == null) {
            return const Center(
              child: Text(
                'Page not found',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          if (pageConfig['type'] == 'main') {
            return GridRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'buzzer') {
            return BuzzerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'text') {
            return TextRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'timer') {
            return TimerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'image') {
            return ImageRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          // For other page types, show a simple text display
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pageConfig['header'] ?? 'Page $currentPage',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  pageConfig['text'] ?? 'No content',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TeamGreenScreen extends StatelessWidget {
  final WebSocketService webSocketService;
  
  const TeamGreenScreen({super.key, required this.webSocketService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: webSocketService,
        builder: (context, child) {
          final config = webSocketService.config;
          final currentPage = webSocketService.currentPage;
          
          if (config.isEmpty) {
            return const Center(
              child: Text(
                'Loading config...',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          final pageConfig = config[currentPage];
          if (pageConfig == null) {
            return const Center(
              child: Text(
                'Page not found',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }
          
          if (pageConfig['type'] == 'main') {
            return GridRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'buzzer') {
            return BuzzerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'text') {
            return TextRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'timer') {
            return TimerRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          if (pageConfig['type'] == 'image') {
            return ImageRenderer(
              webSocketService: webSocketService,
              pageConfig: pageConfig,
            );
          }
          
          // For other page types, show a simple text display
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pageConfig['header'] ?? 'Page $currentPage',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  pageConfig['text'] ?? 'No content',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MasterScreenWrapper extends StatelessWidget {
  final WebSocketService webSocketService;
  
  const MasterScreenWrapper({super.key, required this.webSocketService});

  @override
  Widget build(BuildContext context) {
    return MasterScreen(webSocketService: webSocketService);
  }
} 