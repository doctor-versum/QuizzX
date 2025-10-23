import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _clientId;
  String? _mode;
  List<Map<String, dynamic>> _connectedClients = [];
  bool _disposed = false;
  Map<String, dynamic> _config = {};
  String _currentPage = '0';
  Timer? _reconnectTimer;
  String? _lastServerUrl;
  String? _lastMode;
  Set<String> _pressedButtons = {};
  String _enabledTeam = 'team_red';
  
  String? get lastServerUrl => _lastServerUrl;
  
  bool get isConnected => _isConnected;
  String? get clientId => _clientId;
  String? get mode => _mode;
  List<Map<String, dynamic>> get connectedClients => _connectedClients;
  Map<String, dynamic> get config => _config;
  String get currentPage => _currentPage;
  Set<String> get pressedButtons => _pressedButtons;
  String get enabledTeam => _enabledTeam;

  Future<bool> connect(String serverUrl, String mode) async {
    _lastServerUrl = serverUrl;
    _lastMode = mode;
    return await _connectInternal(serverUrl, mode, false);
  }

  Future<bool> _connectInternal(String serverUrl, String mode, bool isReconnect) async {
    try {
      // Convert HTTP URL to WebSocket URL
      String wsUrl = serverUrl.replaceFirst('http://', 'ws://');
      if (!wsUrl.contains(':')) {
        wsUrl += ':8765'; // Default WebSocket port
      }
      
      debugPrint('${isReconnect ? 'Re' : ''}Connecting to WebSocket: $wsUrl');
      debugPrint('Original server URL: $serverUrl');
      debugPrint('Mode: $mode');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _mode = mode;
      
      // Create a completer to wait for connection confirmation
      final completer = Completer<bool>();
      
      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
          // Check if we received connection confirmation
          if (_isConnected && !completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnection();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _handleDisconnection();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );
      
      // Wait a moment for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Send connection or reconnect message
      _sendMessage({
        'type': isReconnect ? 'reconnect' : 'connect',
        'mode': mode,
      });
      
      // Wait for connection confirmation with timeout
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Connection timeout');
          return false;
        },
      );
    } catch (e) {
      debugPrint('Failed to connect: $e');
      return false;
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    if (!_disposed) {
      notifyListeners();
    }
    
    // Start reconnection timer
    _startReconnectionTimer();
  }

  void _startReconnectionTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_isConnected && _lastServerUrl != null && _lastMode != null) {
        debugPrint('Attempting to reconnect...');
        _connectInternal(_lastServerUrl!, _lastMode!, true);
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];
      
      switch (type) {
        case 'welcome':
          _clientId = data['client_id'];
          debugPrint('Welcome message received: ${data['message']}');
          break;
          
        case 'connection_confirmed':
          _isConnected = true;
          _clientId = data['client_id'];
          _mode = data['mode'];
          debugPrint('Connection confirmed as $_mode');
          if (!_disposed) {
            notifyListeners();
          }
          break;
          
        case 'client_connected':
          debugPrint('New client connected: ${data['client_id']} as ${data['mode']}');
          break;
          
        case 'clients_list':
          _connectedClients = List<Map<String, dynamic>>.from(data['clients']);
          if (!_disposed) {
            notifyListeners();
          }
          break;
          
        case 'pong':
          debugPrint('Pong received at: ${data['timestamp']}');
          break;
          
        case 'config':
          _config = Map<String, dynamic>.from(data['config']);
          debugPrint('Config received: ${_config.length} pages');
          if (!_disposed) {
            notifyListeners();
          }
          break;
          
        case 'switch_page':
          _currentPage = data['page_id'];
          debugPrint('Switching to page: $_currentPage');
          if (!_disposed) {
            notifyListeners();
          }
          break;
          
        case 'render_page':
          _currentPage = data['page_id'];
          debugPrint('Rendering page: $_currentPage');
          
          // Handle pressed buttons and team state for page 0
          if (data['page_id'] == '0') {
            if (data['pressed_buttons'] != null) {
              _pressedButtons = Set<String>.from(data['pressed_buttons']);
              debugPrint('Received pressed buttons: $_pressedButtons');
            }
            if (data['enabled_team'] != null) {
              _enabledTeam = data['enabled_team'];
              debugPrint('Received enabled team: $_enabledTeam');
            }
          }
          
          if (!_disposed) {
            notifyListeners();
          }
          break;
          
        default:
          debugPrint('Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }

  void ping() {
    _sendMessage({
      'type': 'ping',
    });
  }

  void getConnectedClients() {
    _sendMessage({
      'type': 'get_clients',
    });
  }

  void sendGridClick(int row, int col) {
    _sendMessage({
      'type': 'grid_click',
      'row': row,
      'col': col,
    });
  }

  void sendBuzzerPress() {
    _sendMessage({
      'type': 'buzzer_press',
    });
  }

  void sendTimerFinished() {
    _sendMessage({
      'type': 'timer_finished',
    });
  }

  void sendMasterAddPoints(String team, int points) {
    _sendMessage({
      'type': 'master_add_points',
      'team': team,
      'points': points,
    });
  }

  void sendMasterRemovePoints(String team, int points) {
    _sendMessage({
      'type': 'master_remove_points',
      'team': team,
      'points': points,
    });
  }

  void sendMasterEnableTeam(String team) {
    _sendMessage({
      'type': 'master_enable_team',
      'team': team,
    });
  }

  void sendMasterReset() {
    _sendMessage({
      'type': 'master_reset',
    });
  }

  void sendNextSlide() {
    _sendMessage({
      'type': 'next_slide',
    });
  }

  void sendReturnToMain() {
    _sendMessage({
      'type': 'return_to_main',
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _clientId = null;
    _mode = null;
    _connectedClients.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // Only disconnect if we're actually connected
    if (_channel != null) {
      disconnect();
    }
    super.dispose();
  }
} 