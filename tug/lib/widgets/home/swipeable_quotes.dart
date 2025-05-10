// lib/widgets/home/swipeable_quotes.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';

class SwipeableQuotes extends StatefulWidget {
  final List<Map<String, String>> quotes;
  
  const SwipeableQuotes({
    super.key, 
    required this.quotes,
  });

  @override
  State<SwipeableQuotes> createState() => _SwipeableQuotesState();
}

class _SwipeableQuotesState extends State<SwipeableQuotes> {
  late PageController _pageController;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Initialize the page controller
    _pageController = PageController();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _goToNextQuote() {
    final nextIndex = (_currentIndex + 1) % widget.quotes.length;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }
  
  void _goToPreviousQuote() {
    final previousIndex = (_currentIndex - 1 + widget.quotes.length) % widget.quotes.length;
    _pageController.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Quote Cards with PageView for swiping
        SizedBox(
          height: 220, // Fixed height for the quote card
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.quotes.length,
            itemBuilder: (context, index) {
              final quote = widget.quotes[index];
              return _buildQuoteCard(context, quote, isDarkMode);
            },
          ),
        ),
        
        // Pagination Indicators
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: TugColors.primaryPurple.withOpacity(0.7),
              onPressed: _goToPreviousQuote,
              iconSize: 20,
            ),
            
            // Pagination dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.quotes.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? TugColors.primaryPurple
                        : TugColors.primaryPurple.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            
            // Next button
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              color: TugColors.primaryPurple.withOpacity(0.7),
              onPressed: _goToNextQuote,
              iconSize: 20,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuoteCard(BuildContext context, Map<String, String> quote, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TugColors.primaryPurple.withOpacity(isDarkMode ? 0.9 : 0.8),
            TugColors.primaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TugColors.primaryPurple.withOpacity(isDarkMode ? 0.4 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background patterns
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.format_quote,
              size: 100,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Icon(
              Icons.format_quote,
              size: 100,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Values Wisdom',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      quote['quote'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                Text(
                  '— ${quote['author'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}