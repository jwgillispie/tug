// lib/screens/subscription/user_subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/services/subscription_service.dart';
import 'package:tug/utils/theme/colors.dart';

class UserSubscriptionScreen extends StatefulWidget {
  const UserSubscriptionScreen({super.key});

  @override
  State<UserSubscriptionScreen> createState() => _UserSubscriptionScreenState();
}

class _UserSubscriptionScreenState extends State<UserSubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  final _userIdController = TextEditingController();
  String _currentUserId = '';
  bool _isLoading = false;
  bool _isPremium = false;
  bool _isAnonymous = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = await _subscriptionService.getCurrentUserID();
      final isAnonymous = await _subscriptionService.isAnonymousUser();
      
      // Check premium status from the bloc
      final state = context.read<SubscriptionBloc>().state;
      bool isPremium = false;
      if (state is SubscriptionsLoaded) {
        isPremium = state.isPremium;
      } else {
        // Reload subscriptions if not loaded yet
        context.read<SubscriptionBloc>().add(LoadSubscriptions());
      }
      
      if (mounted) {
        setState(() {
          _currentUserId = userId;
          _isAnonymous = isAnonymous;
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Error loading user data: $e');
      }
    }
  }
  
  Future<void> _loginUser() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showError('Please enter a user ID');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _subscriptionService.loginUser(userId);
      if (success) {
        // Refresh data
        await _loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged in'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('Failed to log in');
      }
    } catch (e) {
      _showError('Error logging in: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _logoutUser() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _subscriptionService.logoutUser();
      if (success) {
        // Refresh data
        await _loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged out'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _showError('Failed to log out');
      }
    } catch (e) {
      _showError('Error logging out: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _subscriptionService.restorePurchases();
      if (success) {
        // Refresh data and reload subscription state
        await _loadUserData();
        context.read<SubscriptionBloc>().add(LoadSubscriptions());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError('No purchases found to restore');
      }
    } catch (e) {
      _showError('Error restoring purchases: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Subscription'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : BlocListener<SubscriptionBloc, SubscriptionState>(
              listener: (context, state) {
                if (state is SubscriptionsLoaded) {
                  setState(() {
                    _isPremium = state.isPremium;
                  });
                }
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User ID Section
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Current User ID:'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.grey.shade800 
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _currentUserId,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isAnonymous
                                    ? 'You are using an anonymous account'
                                    : 'You are logged in with a user account',
                                style: TextStyle(
                                  color: _isAnonymous
                                      ? Colors.orange.shade700  // Darker orange for better visibility
                                      : Colors.green.shade600,  // Darker green for better visibility
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,  // Semi-bold for better readability
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Subscription Status Section
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Subscription Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isPremium
                                          ? Colors.green
                                          : Colors.grey,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _isPremium ? 'PREMIUM' : 'FREE',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isPremium
                                        ? 'You have premium access'
                                        : 'Upgrade to unlock premium features',
                                    style: TextStyle(
                                      color: _isPremium
                                          ? Colors.green
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_isPremium) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TugColors.primaryPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    context.push('/subscription');
                                  },
                                  child: const Text('View Subscription Options'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      // Login/Logout Section
                      if (_isAnonymous)
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Login with User ID',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Login with a user ID to sync your purchases across devices.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    "Enter an ID that's memorable to you, like your email (e.g., user@example.com) or a username. You'll need this same ID to access your subscription on other devices.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _userIdController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'User ID',
                                    hintText: 'Enter your email or username',
                                    helperText: 'Example: your.name@gmail.com or username123',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loginUser,
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Logged In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You are currently logged in. You can log out if needed.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: _logoutUser,
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Restore Purchases Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Manage Purchases',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Restore purchases if you reinstalled the app or switched devices.',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: _restorePurchases,
                                child: const Text('Restore Purchases'),
                              ),
                            ],
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
}