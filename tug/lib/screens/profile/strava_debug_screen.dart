// lib/screens/profile/strava_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/services/strava_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class StravaDebugScreen extends StatefulWidget {
  const StravaDebugScreen({Key? key}) : super(key: key);

  @override
  State<StravaDebugScreen> createState() => _StravaDebugScreenState();
}

class _StravaDebugScreenState extends State<StravaDebugScreen> {
  final StravaService _stravaService = StravaService();
  bool _isLoading = false;
  String _accessToken = '';
  String _redirectUri = '';
  String _clientId = '';
  String _statusMessage = '';
  bool _isConnected = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading...';
    });
    
    try {
      // Load the client ID and redirect URI from .env
      _clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? 'Not set';
      _redirectUri = dotenv.env['STRAVA_REDIRECT_URI'] ?? 'http://localhost';
      
      // Check connection status
      _isConnected = await _stravaService.isConnected();
      
      // Get stored token
      final token = await _stravaService.getAccessToken();
      if (token != null) {
        _accessToken = token;
      }
      
      setState(() {
        _statusMessage = _isConnected 
            ? 'Connected to Strava' 
            : 'Not connected to Strava';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _connect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to Strava...';
    });
    
    try {
      final result = await _stravaService.connect();
      
      setState(() {
        if (result.success) {
          _statusMessage = 'Connected successfully!';
          _isConnected = true;
          if (result.accessToken != null) {
            _accessToken = result.accessToken!;
          }
        } else {
          _statusMessage = 'Connection failed: ${result.errorMessage ?? "Unknown error"}';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _disconnect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Disconnecting from Strava...';
    });
    
    try {
      final success = await _stravaService.disconnect();
      
      setState(() {
        if (success) {
          _statusMessage = 'Disconnected successfully!';
          _isConnected = false;
          _accessToken = '';
        } else {
          _statusMessage = 'Disconnection failed';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  Future<void> _openStravaAPI() async {
    final uri = Uri.parse('https://www.strava.com/settings/api');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Strava API page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strava Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status section
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isConnected ? Icons.check_circle : Icons.error,
                                color: _isConnected ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.link),
                                label: const Text('Connect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TugColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isLoading || _isConnected ? null : _connect,
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.link_off),
                                label: const Text('Disconnect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isLoading || !_isConnected ? null : _disconnect,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Configuration section
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Strava API Configuration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Client ID
                          _buildInfoRow(
                            title: 'Client ID:',
                            value: _clientId,
                            onCopy: () => _copyToClipboard(
                              _clientId,
                              'Client ID copied to clipboard',
                            ),
                          ),
                          
                          const Divider(),
                          
                          // Redirect URI
                          _buildInfoRow(
                            title: 'Redirect URI:',
                            value: _redirectUri,
                            onCopy: () => _copyToClipboard(
                              _redirectUri,
                              'Redirect URI copied to clipboard',
                            ),
                          ),
                          
                          const Divider(),
                          
                          // Access Token
                          _buildInfoRow(
                            title: 'Access Token:',
                            value: _accessToken.isEmpty
                                ? 'Not available'
                                : _accessToken.length > 15
                                    ? '${_accessToken.substring(0, 15)}...'
                                    : _accessToken,
                            onCopy: _accessToken.isEmpty
                                ? null
                                : () => _copyToClipboard(
                                      _accessToken,
                                      'Access token copied to clipboard',
                                    ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Open Strava API button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open Strava API Settings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFC5200), // Strava orange
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _openStravaAPI,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.code),
                              label: const Text('Enter Auth Code Manually'),
                              onPressed: () {
                                context.push('/strava-code-input');
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Make sure your redirect URI in Strava settings matches exactly: $_redirectUri',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Troubleshooting section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Troubleshooting',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTroubleshootingItem(
                            'If you get "bad request" or "redirect_uri invalid" errors:',
                            [
                              'Make sure the Callback Domain is set to "tug" in your Strava API settings',
                              'Check that the Authorization Callback Domain field is correct',
                              'Try using the domain name without http:// or https://',
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTroubleshootingItem(
                            'If the app doesn\'t receive the callback:',
                            [
                              'Ensure the app is installed on your device',
                              'Check that the URL scheme is properly configured in AndroidManifest.xml and Info.plist',
                              'Try restarting the app after connecting',
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoRow({
    required String title,
    required String value,
    Function()? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: onCopy,
              tooltip: 'Copy to clipboard',
            ),
        ],
      ),
    );
  }
  
  Widget _buildTroubleshootingItem(String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(step)),
                ],
              ),
            )),
      ],
    );
  }
}