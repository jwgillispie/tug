// lib/widgets/profile/strava_import_widget.dart
import 'package:flutter/material.dart';
import 'package:tug/services/strava_service.dart';
import 'package:tug/utils/theme/colors.dart';

class StravaImportWidget extends StatefulWidget {
  final Function(bool) onConnectionStatusChanged;

  const StravaImportWidget({
    super.key,
    required this.onConnectionStatusChanged,
  });

  @override
  State<StravaImportWidget> createState() => _StravaImportWidgetState();
}

class _StravaImportWidgetState extends State<StravaImportWidget> {
  final StravaService _stravaService = StravaService();
  bool _isConnected = false;
  bool _isLoading = true;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _checkStravaConnection();
  }

  Future<void> _checkStravaConnection() async {
    setState(() {
      _isLoading = true;
    });

    final isConnected = await _stravaService.isConnected();

    setState(() {
      _isConnected = isConnected;
      _isLoading = false;
    });

    widget.onConnectionStatusChanged(_isConnected);
  }

  Future<void> _connectToStrava() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    final result = await _stravaService.connect();

    setState(() {
      _isConnected = result.success;
      _isConnecting = false;
    });

    widget.onConnectionStatusChanged(_isConnected);
  }

  Future<void> _disconnectFromStrava() async {
    final success = await _stravaService.disconnect();

    if (success) {
      setState(() {
        _isConnected = false;
      });

      widget.onConnectionStatusChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          : InkWell(
              onTap: _isConnected ? null : _connectToStrava,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isConnected
                        ? TugColors.success.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  color: _isConnected
                      ? TugColors.success.withOpacity(isDarkMode ? 0.1 : 0.05)
                      : null,
                ),
                child: Row(
                  children: [
                    // Strava logo (orange)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC5200), // Strava orange
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Image.network(
                          'https://cdn.iconscout.com/icon/free/png-256/free-strava-3629751-3031711.png',
                          width: 30,
                          height: 30,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.directions_run,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Information text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected
                                ? 'Connected to Strava'
                                : 'Connect with Strava',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isConnected
                                ? 'Your Strava activities can be imported'
                                : 'Import your runs, rides and other activities',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Connect/disconnect button
                    _isConnecting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : _isConnected
                            ? TextButton(
                                onPressed: _disconnectFromStrava,
                                child: const Text('Disconnect'),
                              )
                            : Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.3),
                              ),
                  ],
                ),
              ),
            ),
    );
  }
}
