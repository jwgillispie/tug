// lib/screens/diagnostic_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firebase_diagnostics.dart';
import '../utils/theme/buttons.dart';
import '../widgets/common/tug_text_field.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _diagnostics = FirebaseDiagnostics();
  
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic> _firebaseStatus = {};
  Map<String, dynamic> _currentUser = {};
  
  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _checkFirebaseStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking Firebase status...';
    });
    
    try {
      final status = await _diagnostics.checkFirebaseStatus();
      
      setState(() {
        _firebaseStatus = status;
        _statusMessage = status['status'] == 'success' 
            ? 'Firebase initialized successfully' 
            : 'Firebase initialization issues detected';
      });
      
      // Also get current user details
      _getCurrentUser();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking Firebase status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getCurrentUser() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Getting current user...';
    });
    
    try {
      final userDetails = await _diagnostics.getCurrentUserDetails();
      
      setState(() {
        _currentUser = userDetails;
        _statusMessage = userDetails['signed_in'] 
            ? 'User is signed in' 
            : 'No user is signed in';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting current user: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and password';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing sign in...';
    });
    
    try {
      await _diagnostics.printAllDiagnostics(
        _emailController.text, 
        _passwordController.text
      );
      
      // Also try a direct sign in
      final auth = FirebaseAuth.instance;
      
      try {
        await auth.signOut();
      } catch (e) {
        // Ignore sign out errors during testing
      }
      
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        setState(() {
          _statusMessage = 'Sign in successful. User: ${credential.user?.uid}';
        });
        
        // Refresh current user details
        _getCurrentUser();
      } catch (e) {
        setState(() {
          _statusMessage = 'Sign in error: $e';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error testing sign in: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing out...';
    });
    
    try {
      await FirebaseAuth.instance.signOut();
      
      setState(() {
        _statusMessage = 'Sign out successful';
      });
      
      // Refresh current user details
      _getCurrentUser();
    } catch (e) {
      setState(() {
        _statusMessage = 'Sign out error: $e';
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
        title: const Text('Firebase Diagnostics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Text(_statusMessage),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Firebase Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ..._firebaseStatus.entries.map((entry) {
                      if (entry.key == 'options' && entry.value is Map) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Options:'),
                            ...(entry.value as Map).entries.map((option) => 
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text('${option.key}: ${option.value}'),
                              )
                            ),
                          ],
                        );
                      }
                      return Text('${entry.key}: ${entry.value}');
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current User
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_currentUser.isEmpty)
                      const Text('No user information available')
                    else if (_currentUser['signed_in'] == false)
                      Text('${_currentUser['message']}')
                    else
                      ..._currentUser.entries
                          .where((entry) => entry.key != 'provider_data' && entry.value != null)
                          .map((entry) => Text('${entry.key}: ${entry.value}')),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Sign In
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Authentication',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TugTextField(
                      label: 'Email',
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    TugTextField(
                      label: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                            onPressed: _isLoading ? null : _testSignIn,
                            child: const Text('Test Sign In'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            style: TugButtons.secondaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                            onPressed: _isLoading ? null : _signOut,
                            child: const Text('Sign Out'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: TugButtons.primaryButtonStyle(isDark: Theme.of(context).brightness == Brightness.dark),
                onPressed: _isLoading ? null : _checkFirebaseStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}