// lib/widgets/social/balance_accountability_widget.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';
import '../../utils/mobile_ux_utils.dart';
import '../../models/user_model.dart';

class BalanceAccountabilityWidget extends StatefulWidget {
  final UserModel? currentUser;
  final List<AccountabilityPartner> partners;
  final Function(String userId) onAddPartner;
  final Function(String partnerId) onRemovePartner;
  final Function(String partnerId, String message) onSendEncouragement;
  
  const BalanceAccountabilityWidget({
    super.key,
    this.currentUser,
    required this.partners,
    required this.onAddPartner,
    required this.onRemovePartner,
    required this.onSendEncouragement,
  });

  @override
  State<BalanceAccountabilityWidget> createState() => _BalanceAccountabilityWidgetState();
}

class _BalanceAccountabilityWidgetState extends State<BalanceAccountabilityWidget> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'Balance Accountability: ${widget.partners.length} accountability partners',
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDarkMode),
            const SizedBox(height: 16),
            if (widget.partners.isEmpty)
              _buildEmptyState(isDarkMode)
            else
              _buildPartnersList(isDarkMode),
            const SizedBox(height: 16),
            _buildAddPartnerButton(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.2),
                Colors.red.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.handshake,
            color: Colors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance Buddies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? TugColors.darkTextPrimary : TugColors.lightTextPrimary,
                ),
              ),
              Text(
                'Friends keeping you accountable on both sides',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? TugColors.darkTextSecondary : TugColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        if (widget.partners.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.partners.length}',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPartnersList(bool isDarkMode) {
    return Column(
      children: widget.partners.map((partner) => 
        _buildPartnerCard(partner, isDarkMode)).toList(),
    );
  }

  Widget _buildPartnerCard(AccountabilityPartner partner, bool isDarkMode) {
    return Semantics(
      label: '${partner.displayName}, balance buddy. Values: ${partner.valuesProgress}%, Vices: ${partner.vicesProgress}%',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? TugColors.darkSurface : Colors.white,
              isDarkMode 
                  ? TugColors.darkSurface.withValues(alpha: 0.8)
                  : Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Profile picture placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.3),
                        Colors.red.withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.orange.withValues(alpha: 0.8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            partner.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode 
                                  ? TugColors.darkTextPrimary 
                                  : TugColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (partner.isOnline)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Balance Buddy since ${_formatJoinDate(partner.partnershipDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode 
                              ? TugColors.darkTextSecondary 
                              : TugColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'encourage') {
                      _showEncouragementDialog(partner);
                    } else if (value == 'remove') {
                      _showRemovePartnerDialog(partner);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'encourage',
                      child: Row(
                        children: [
                          Icon(Icons.favorite, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Send Encouragement'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, size: 18, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Remove Partner'),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: isDarkMode 
                        ? TugColors.darkTextSecondary 
                        : TugColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Balance progress bars
            Row(
              children: [
                Expanded(
                  child: _buildProgressBar(
                    'Values',
                    partner.valuesProgress,
                    TugColors.primaryPurple,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressBar(
                    'Vices',
                    partner.vicesProgress,
                    TugColors.viceGreen,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            
            if (partner.lastActivity != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last activity: ${partner.lastActivity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDarkMode 
                ? TugColors.darkTextSecondary 
                : TugColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.grey.shade700 
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: progress / 100,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${progress.toInt()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? TugColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
              ? Colors.grey.shade700 
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 48,
            color: isDarkMode 
                ? Colors.grey.shade500 
                : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Balance Buddies Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode 
                  ? TugColors.darkTextPrimary 
                  : TugColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add accountability partners to keep each other motivated on both values and vices!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode 
                  ? TugColors.darkTextSecondary 
                  : TugColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPartnerButton(bool isDarkMode) {
    return MobileUXUtils.mobileButton(
      onPressed: () => _showAddPartnerDialog(),
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Balance Buddy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartnerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Balance Buddy'),
        content: const Text('Enter your friend\'s username or email to send them a balance buddy request.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement add partner logic
              Navigator.pop(context);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showEncouragementDialog(AccountabilityPartner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Encourage ${partner.displayName}'),
        content: const Text('Send a motivational message to your balance buddy!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onSendEncouragement(partner.userId, 'Keep up the great work! 💪');
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showRemovePartnerDialog(AccountabilityPartner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${partner.displayName}?'),
        content: const Text('Are you sure you want to remove this balance buddy? You can always add them back later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onRemovePartner(partner.userId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}m ago';
    }
  }
}

class AccountabilityPartner {
  final String userId;
  final String displayName;
  final bool isOnline;
  final double valuesProgress;
  final double vicesProgress;
  final DateTime partnershipDate;
  final String? lastActivity;
  
  const AccountabilityPartner({
    required this.userId,
    required this.displayName,
    required this.isOnline,
    required this.valuesProgress,
    required this.vicesProgress,
    required this.partnershipDate,
    this.lastActivity,
  });
}