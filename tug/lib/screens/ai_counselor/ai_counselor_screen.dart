// lib/screens/ai_counselor/ai_counselor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/theme/colors.dart';
import '../../services/app_mode_service.dart';
import '../../services/ai_counselor_service.dart';
import '../../blocs/vices/bloc/vices_bloc.dart';
import '../../blocs/vices/bloc/vices_state.dart';
import '../../models/vice_model.dart';

class AICounselorScreen extends StatefulWidget {
  const AICounselorScreen({super.key});

  @override
  State<AICounselorScreen> createState() => _AICounselorScreenState();
}

class _AICounselorScreenState extends State<AICounselorScreen> {
  final AppModeService _appModeService = AppModeService();
  final AICounselorService _aiCounselorService = AICounselorService();
  AppMode _currentMode = AppMode.valuesMode;
  List<ViceModel> _userVices = [];
  String? _dailyAffirmation;
  bool _isLoadingAffirmation = false;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _initializeAIService();
    _loadUserVices();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    _appModeService.modeStream.listen((mode) {
      if (mounted) {
        setState(() {
          _currentMode = mode;
        });
      }
    });
    setState(() {
      _currentMode = _appModeService.currentMode;
    });
  }

  Future<void> _initializeAIService() async {
    try {
      await _aiCounselorService.initialize();
    } catch (e) {
      // Service will use fallback responses if initialization fails
    }
  }

  void _loadUserVices() {
    final vicesState = context.read<VicesBloc>().state;
    if (vicesState is VicesLoaded) {
      setState(() {
        _userVices = vicesState.vices;
      });
      _generateDailyAffirmation();
    }
  }

  Future<void> _generateDailyAffirmation() async {
    if (_userVices.isEmpty) return;
    
    setState(() {
      _isLoadingAffirmation = true;
    });

    try {
      final affirmation = await _aiCounselorService.generatePersonalizedAffirmation(
        userVices: _userVices,
      );
      
      setState(() {
        _dailyAffirmation = affirmation;
        _isLoadingAffirmation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAffirmation = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TugColors.viceRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: TugColors.viceRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Daily Affirmation'),
          ],
        ),
        backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TugColors.getBackgroundColor(isDarkMode, isViceMode),
              Color.lerp(
                TugColors.getBackgroundColor(isDarkMode, isViceMode),
                TugColors.viceRed,
                0.05,
              ) ?? TugColors.getBackgroundColor(isDarkMode, isViceMode),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Affirmation Card
                if (_dailyAffirmation != null || _isLoadingAffirmation)
                  _buildAffirmationCard(isDarkMode),
                
                const SizedBox(height: 32),
                
                // Info text
                Text(
                  'Your personalized affirmation is created based on your current vices and progress. Tap the refresh icon to generate a new one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode 
                        ? TugColors.darkTextSecondary 
                        : TugColors.lightTextSecondary,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Generate button if no affirmation yet
                if (_dailyAffirmation == null && !_isLoadingAffirmation)
                  ElevatedButton.icon(
                    onPressed: _generateDailyAffirmation,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate My Affirmation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TugColors.viceRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAffirmationCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.viceRed,
            TugColors.viceOrange,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.viceRed.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Daily Affirmation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoadingAffirmation)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                GestureDetector(
                  onTap: _generateDailyAffirmation,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingAffirmation)
            const Text(
              'Creating your personal affirmation...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (_dailyAffirmation != null)
            Text(
              _dailyAffirmation!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Affirmation'),
        content: const Text(
          'This feature creates personalized affirmations based on your tracked vices and progress. These motivational messages are designed to support your journey and remind you of your inner strength.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}