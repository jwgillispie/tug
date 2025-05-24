// lib/screens/subscription/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tug/blocs/subscription/subscription_bloc.dart';
import 'package:tug/models/subscription_model.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/common/loading_overlay.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool showCloseButton;
  
  const SubscriptionScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    // Load subscriptions when screen opens
    context.read<SubscriptionBloc>().add(LoadSubscriptions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        leading: widget.showCloseButton
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () {
              context.read<SubscriptionBloc>().add(RestorePurchases());
            },
            child: const Text(
              'Restore',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is PurchaseSuccess) {
            // Show success message and close
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription purchased successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is PurchaseError) {
            // Check if it's a cancellation (don't show error for user cancellations)
            final message = state.message.toLowerCase();
            final isCancelled = message.contains('cancel') || 
                                message.contains('user cancelled') ||
                                message.contains('purchase_cancelled') ||
                                message.contains('usercancelled: true');
            
            if (!isCancelled) {
              // Only show error for real errors, not cancellations
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
            
            // For both cancellations and errors, leave the state as SubscriptionLoading
            // This will make the listener fetch subscriptions again in the next cycle
            context.read<SubscriptionBloc>().add(LoadSubscriptions());
          } else if (state is PurchasesRestored) {
            // Show restoration message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.hasPremium
                      ? 'Premium subscription restored!'
                      : 'No premium subscription found to restore.',
                ),
                backgroundColor: state.hasPremium ? Colors.green : Colors.orange,
              ),
            );
            
            // Close if successfully restored
            if (state.hasPremium) {
              context.pop();
            }
          }
        },
        builder: (context, state) {
          // Show loading indicator if loading
          if (state is SubscriptionLoading || 
              state is PurchaseInProgress ||
              state is RestoringPurchases) {
            return const LoadingOverlay(
              isLoading: true,
              child: _SubscriptionContent(
                subscriptions: [],
                isPremium: false,
              ),
            );
          }
          
          // Show subscriptions if loaded
          if (state is SubscriptionsLoaded) {
            return LoadingOverlay(
              isLoading: false,
              child: _SubscriptionContent(
                subscriptions: state.subscriptions,
                isPremium: state.isPremium,
              ),
            );
          }
          
          // Show error if failed
          if (state is SubscriptionError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SubscriptionBloc>().add(LoadSubscriptions());
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Return loading by default
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  final List<SubscriptionModel> subscriptions;
  final bool isPremium;

  const _SubscriptionContent({
    required this.subscriptions,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isPremium) {
      return _buildPremiumContent(context);
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium benefits
            const SizedBox(height: 16),
            Text(
              'Tug Premium',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: TugColors.primaryPurple,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Feature bullets
            ..._buildFeaturesList(context),
            
            const SizedBox(height: 32),
            
            // Subscription options
            if (subscriptions.isNotEmpty) ...[
              Text(
                'Choose a Plan',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...subscriptions.map((subscription) => _buildSubscriptionOption(
                    context,
                    subscription,
                  )),
            ],
            
            const SizedBox(height: 24),
            
            // Restore purchases button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: OutlinedButton(
                onPressed: () {
                  context.read<SubscriptionBloc>().add(RestorePurchases());
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text('Restore Previous Purchases'),
              ),
            ),
            
            // Terms and privacy note
            Text(
              'Payment will be charged to your Apple ID or Google Play account at confirmation of purchase. '
              'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. '
              'Manage your subscriptions in your account settings after purchase.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // Navigate to terms of service
                    context.push('/terms');
                  },
                  child: const Text('Terms of Service'),
                ),
                const Text('•'),
                TextButton(
                  onPressed: () {
                    // Navigate to privacy policy
                    context.push('/privacy');
                  },
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget for an already-premium user
  Widget _buildPremiumContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'You have an active Premium subscription!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You have access to all premium features. Thank you for your support!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Continue to App'),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                // For iOS - Open subscription settings
                // This is just a placeholder - manage your subscriptions logic here
              },
              child: const Text('Manage Subscription'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build subscription option card
  Widget _buildSubscriptionOption(
    BuildContext context, 
    SubscriptionModel subscription,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: subscription.isPopular
            ? BorderSide(
                color: TugColors.primaryPurple,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.read<SubscriptionBloc>().add(
                PurchaseSubscription(subscription),
              );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (subscription.isPopular) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4, 
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TugColors.primaryPurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subscription.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (subscription.package.packageType == PackageType.annual &&
                            subscription.savingsComparedToMonthly != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subscription.savingsComparedToMonthly!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        subscription.formattedPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.period,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build premium features list
  List<Widget> _buildFeaturesList(BuildContext context) {
    final features = [
      {
        'icon': Icons.remove_circle,
        'title': 'No Ads',
        'description': 'Enjoy an ad-free experience',
      },
      {
        'icon': Icons.analytics,
        'title': 'Advanced Analytics',
        'description': 'Detailed insights and progress tracking',
      },
      {
        'icon': Icons.color_lens,
        'title': 'Custom Themes',
        'description': 'Personalize your app experience',
      },
      {
        'icon': Icons.backup,
        'title': 'Cloud Backup',
        'description': 'Keep your data safe across devices',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Priority Support',
        'description': 'Get help when you need it most',
      },
    ];
    
    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TugColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: TugColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    feature['description'] as String,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}