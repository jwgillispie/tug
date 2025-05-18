// lib/screens/profile/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tug/services/strava_service.dart';
import 'package:tug/services/values_service.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/models/value_model.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);

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

    final result = await _stravaService.connect();

    setState(() {
      _isStravaConnected = result.success;
      if (result.success) {
        _stravaAccessToken = result.accessToken;
      }
      _isConnecting = false;
    });

    if (!result.success) {
      _showErrorDialog('Failed to connect to Strava',
          result.errorMessage ?? 'Unknown error');
    }
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
                                  value.color!.replaceAll('#', '0xFF')))
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
