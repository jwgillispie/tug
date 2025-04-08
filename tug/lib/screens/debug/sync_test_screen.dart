// lib/screens/debug/sync_test_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/auth_sync_tester.dart';
import '../../utils/theme/buttons.dart';
import '../../utils/theme/colors.dart';

class SyncTestScreen extends StatefulWidget {
  const SyncTestScreen({Key? key}) : super(key: key);

  @override
  State<SyncTestScreen> createState() => _SyncTestScreenState();
}

class _SyncTestScreenState extends State<SyncTestScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _testResults = {};
  final _authSyncTester = AuthSyncTester();

  Future<void> _runSyncTest() async {
    setState(() {
      _isLoading = true;
      _testResults = {};
    });

    try {
      final results = await _authSyncTester.testSync();
      setState(() {
        _testResults = results;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'success': false,
          'errors': ['Test failed with error: $e'],
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Sync Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Auth & MongoDB Sync Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This tool tests the synchronization between Firebase Auth and your MongoDB backend.',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: TugButtons.primaryButtonStyle,
              onPressed: _isLoading ? null : _runSyncTest,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Run Sync Test'),
            ),
            const SizedBox(height: 24),
            _buildTestResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults.isEmpty) {
      return const Center(
        child: Text('Run the test to see results.'),
      );
    }

    final success = _testResults['success'] == true;
    final errors = _testResults['errors'] as List<dynamic>? ?? [];

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: success
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: success ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      success
                          ? 'Sync test completed successfully'
                          : 'Sync test failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: success ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildResultItem(
              'Firebase Auth',
              _testResults['firebase_auth'] == true,
            ),
            _buildResultItem(
              'Token Valid',
              _testResults['token_valid'] == true,
            ),
            _buildResultItem(
              'MongoDB Sync',
              _testResults['mongodb_sync'] == true,
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Errors:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...errors.map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )),
            ],
            if (_testResults['firebase_user'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Firebase User:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildUserInfo(_testResults['firebase_user']),
            ],
            if (_testResults['backend_profile'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Backend Profile:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildUserInfo(_testResults['backend_profile']),
            ],
            // Current user state
            const SizedBox(height: 24),
            const Text(
              'Current Firebase User:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildCurrentUserInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: user.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value?.toString() ?? 'null',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No user is currently signed in.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoRow('UID', user.uid),
            _buildUserInfoRow('Email', user.email),
            _buildUserInfoRow('Display Name', user.displayName),
            _buildUserInfoRow('Email Verified', user.emailVerified.toString()),
            _buildUserInfoRow('Provider ID', user.providerData.isNotEmpty 
                ? user.providerData[0].providerId
                : 'none'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'null',
            ),
          ),
        ],
      ),
    );
  }
}