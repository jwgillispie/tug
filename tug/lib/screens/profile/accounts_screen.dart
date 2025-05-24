// lib/screens/profile/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/services/strava_service.dart';
import 'package:tug/services/values_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/models/value_model.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final StravaService _stravaService = StravaService();
  final ValuesService _valuesService = ValuesService();

  bool _isStravaConnected = false;
  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isRefreshing = false;
  String? _stravaAccessToken;

  ValueModel? _selectedValue;
  List<ValueModel> _userValues = [];

  @override
  void initState() {
    super.initState();
    _checkStravaConnection();
    _loadUserValues();
  }

  Future<void> _checkStravaConnection() async {
    setState(() {
      _isLoading = true;
    });

    final isConnected = await _stravaService.isConnected();
    final token = await _stravaService.getAccessToken();

    setState(() {
      _isStravaConnected = isConnected;
      _stravaAccessToken = token;
      _isLoading = false;
    });
  }

  Future<void> _loadUserValues() async {
    try {
      final values = await _valuesService.getValues();

      // Get the default value from local storage if set
      final defaultValueId = await _stravaService.getDefaultValueId();

      setState(() {
        _userValues = values;
        if (defaultValueId != null) {
          _selectedValue = values.firstWhere(
            (v) => v.id == defaultValueId,
            orElse: () => values.isNotEmpty ? values.first : values.first,  // This should never actually return null if values is not empty
          );
        } else if (values.isNotEmpty) {
          _selectedValue = values.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading user values: $e');
    }
  }

  Future<void> _connectToStrava() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    // First try the automatic OAuth flow
    final result = await _stravaService.connect();

    // If it failed, offer the manual code entry option
    if (!result.success) {
      setState(() {
        _isConnecting = false;
      });
      
      bool tryManualEntry = false;
      
      // Check if this is a redirect error (common on Safari/iOS)
      // If so, we can go directly to manual entry for a better user experience
      if (result.redirectError) {
        // Show a simplified dialog explaining the issue
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Browser Redirect Issue'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The browser could not complete the redirect to "localhost". This is a common issue on mobile devices.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You will now be redirected to a screen where you can manually enter the authorization code.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Go back to the Strava authorization page in your browser',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '2. Complete the authorization (if you have not already)',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '3. Copy the code from the URL (it will be after "code=" in the URL)',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Need help? Tap "How to Find the Code" on the next screen.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TugColors.primaryPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue to Manual Entry'),
              ),
            ],
          ),
        );
        
        // Automatically proceed to manual entry
        tryManualEntry = true;
      } else {
        // Show standard dialog asking if they want to try manual code entry
        tryManualEntry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error: ${result.errorMessage ?? 'Unknown error'}'),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to enter the authorization code manually?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This option is useful if the automatic redirect is not working.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TugColors.primaryPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enter Code Manually'),
              ),
            ],
          ),
        ) ?? false;
      }
      
      if (tryManualEntry && mounted) {
        // Navigate to the manual code input screen
        final success = await context.push<bool>('/strava-code-input') ?? false;
        
        if (success && mounted) {
          // Refresh the state if manually connected
          await _checkStravaConnection();
          return;
        }
      }
      
      // Show error dialog if manual entry wasn't chosen or failed
      if (mounted && !_isStravaConnected) {
        _showErrorDialog('Failed to connect to Strava',
            result.errorMessage ?? 'Unknown error');
      }
      return;
    }

    // If automatic OAuth worked, update the state
    setState(() {
      _isStravaConnected = result.success;
      if (result.success) {
        _stravaAccessToken = result.accessToken;
      }
      _isConnecting = false;
    });
  }

  Future<void> _disconnectFromStrava() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disconnect Strava'),
            content: const Text(
                'Are you sure you want to disconnect your Strava account? You will no longer receive automatic activity imports.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await _stravaService.disconnect();

    if (success) {
      setState(() {
        _isStravaConnected = false;
        _stravaAccessToken = null;
      });
    } else {
      _showErrorDialog('Disconnect Failed', 'Failed to disconnect from Strava');
    }
  }

  Future<void> _refreshActivities() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final activities = await _stravaService.getActivities(limit: 5);

      if (_selectedValue != null) {
        final importResult = await _stravaService.importActivities(
          activities,
          _selectedValue!.id ?? '',  // Ensure non-null string
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Imported ${importResult.importedCount} activities'),
              backgroundColor: TugColors.success,
            ),
          );
        }
      } else {
        _showErrorDialog('Import Failed',
            'Please select a default value for your activities');
      }
    } catch (e) {
      _showErrorDialog('Refresh Failed', e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _saveDefaultValue() async {
    if (_selectedValue == null) return;

    final success = await _stravaService.setDefaultValueId(_selectedValue!.id ?? '');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default value saved'),
          backgroundColor: TugColors.success,
        ),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Accounts'),
        actions: [
          // Help button for Strava setup
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Strava Setup Guide',
            onPressed: () {
              context.push('/strava-setup-guide');
            },
          ),
          // Debug button for Strava
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Strava Debug',
            onPressed: () {
              context.push('/strava-debug');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStravaSection(isDarkMode),
                if (_isStravaConnected) ...[
                  const SizedBox(height: 24),
                  _buildStravaSettings(isDarkMode),
                ],
              ],
            ),
    );
  }

  Widget _buildStravaSection(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Strava logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC5200), // Strava orange
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Strava',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _isStravaConnected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isStravaConnected ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isStravaConnected
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Import activities from your Strava account',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isStravaConnected && _stravaAccessToken != null) ...[
              const Text(
                'Access Token',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? TugColors.darkSurfaceVariant
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _stravaAccessToken!.length > 30
                            ? '${_stravaAccessToken!.substring(0, 30)}...'
                            : _stravaAccessToken!,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _stravaAccessToken!),
                        ).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: _isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Refresh Activities'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TugColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isRefreshing ? null : _refreshActivities,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _disconnectFromStrava,
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Connect with Strava'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC5200), // Strava orange
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _isConnecting ? null : _connectToStrava,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStravaSettings(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Strava Import Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Default Value for Imported Activities',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'New activities from Strava will automatically be assigned to this value',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedValue?.id,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              hint: const Text('Select a value'),
              items: _userValues.map((value) {
                return DropdownMenuItem<String>(
                  value: value.id,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: value.color != null
                              ? Color(int.parse(
                                  value.color.replaceAll('#', '0xFF')))
                              : TugColors.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(value.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedValue = _userValues.firstWhere(
                      (v) => v.id == newValue,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Default Value'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TugColors.primaryPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _selectedValue != null ? _saveDefaultValue : null,
            ),
          ],
        ),
      ),
    );
  }
}
