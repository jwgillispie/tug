// lib/services/ai_insight_service.dart
// AI-powered insight generation using Firebase Vertex AI Gemini

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/widgets/home/value_insights.dart';
import 'package:flutter/material.dart';

class AIInsightService {
  static final AIInsightService _instance = AIInsightService._internal();
  factory AIInsightService() => _instance;
  AIInsightService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  /// Initialize the Firebase AI model
  Future<void> initialize() async {
    try {
      // Try to initialize Firebase AI - for now just skip AI and use fallback
      // The Firebase AI setup requires additional configuration
      developer.log('AI service temporarily using fallback mode');
      _isInitialized = false; // Force fallback for now
    } catch (e) {
      developer.log('Failed to initialize AI Insight Service: $e');
      _isInitialized = false;
    }
  }

  /// Generate AI-powered insights for user's values and activities
  Future<List<ValueInsight>> generateInsights({
    required List<ValueModel> values,
    required Map<String, Map<String, dynamic>> activityData,
    required Map<String, dynamic>? statistics,
    required String timeframe,
    List<Map<String, dynamic>>? individualActivities,
    Map<String, List<Map<String, dynamic>>>? activitiesByValue,
  }) async {
    if (!_isInitialized || _model == null) {
      return _generateFallbackInsights(values, activityData, individualActivities);
    }

    try {
      final prompt = _buildInsightPrompt(values, activityData, statistics, timeframe, individualActivities, activitiesByValue);
      
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]);

      if (response.text != null) {
        return _parseAIResponse(response.text!, values, activityData, individualActivities);
      } else {
        developer.log('AI response was null, falling back to conditional insights');
        return _generateFallbackInsights(values, activityData, individualActivities);
      }
    } catch (e) {
      developer.log('AI insight generation failed: $e');
      return _generateFallbackInsights(values, activityData, individualActivities);
    }
  }

  /// Generate insights specifically for a single value
  Future<List<ValueInsight>> generateValueSpecificInsights({
    required ValueModel value,
    required Map<String, dynamic> activityData,
    required String timeframe,
    required List<Map<String, dynamic>> recentActivities,
  }) async {
    if (!_isInitialized || _model == null) {
      return _generateValueSpecificFallbackInsights(value, activityData, recentActivities);
    }

    try {
      final prompt = _buildValueSpecificPrompt(value, activityData, timeframe, recentActivities);
      
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]);

      if (response.text != null) {
        return _parseAIResponse(response.text!, [value], {value.name: activityData}, recentActivities);
      } else {
        developer.log('AI response was null for value-specific insights');
        return _generateValueSpecificFallbackInsights(value, activityData, recentActivities);
      }
    } catch (e) {
      developer.log('Value-specific AI insight generation failed: $e');
      return _generateValueSpecificFallbackInsights(value, activityData, recentActivities);
    }
  }

  /// Build a comprehensive prompt for the AI model
  String _buildInsightPrompt(
    List<ValueModel> values,
    Map<String, Map<String, dynamic>> activityData,
    Map<String, dynamic>? statistics,
    String timeframe,
    List<Map<String, dynamic>>? individualActivities,
    Map<String, List<Map<String, dynamic>>>? activitiesByValue,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln("""
You are a personal values alignment coach helping users understand their behavior patterns and providing actionable insights. 

Generate 2-3 personalized insights based on this user's data for their $timeframe progress. Focus on specific activities they've logged and suggest concrete next actions.

USER VALUES & ACTIVITY DATA:
""");

    // Add each value's data with specific activities
    for (final value in values) {
      final activity = activityData[value.name] ?? {'minutes': 0, 'community_avg': 60};
      final minutes = activity['minutes'] as int;
      final communityAvg = activity['community_avg'] as int;
      
      buffer.writeln("• ${value.name}:");
      buffer.writeln("  - Stated Importance: ${value.importance}/5");
      buffer.writeln("  - Time Spent: $minutes minutes");
      buffer.writeln("  - Community Average: $communityAvg minutes");
      
      // Add specific activities for this value if available
      if (activitiesByValue != null && activitiesByValue.containsKey(value.id)) {
        final valueActivities = activitiesByValue[value.id]!;
        if (valueActivities.isNotEmpty) {
          buffer.writeln("  - Recent Activities:");
          for (final act in valueActivities.take(5)) { // Limit to 5 most recent
            buffer.writeln("    * ${act['name']} (${act['duration']} mins)");
            if (act['notes'] != null && act['notes'].toString().isNotEmpty) {
              buffer.writeln("      Notes: ${act['notes']}");
            }
          }
        }
      }
      buffer.writeln();
    }

    // Add recent activity patterns
    if (individualActivities != null && individualActivities.isNotEmpty) {
      buffer.writeln("RECENT ACTIVITY PATTERNS:");
      
      // Group activities by name to find patterns
      final Map<String, List<Map<String, dynamic>>> activityPatterns = {};
      for (final activity in individualActivities) {
        final name = activity['name'] as String;
        if (!activityPatterns.containsKey(name)) {
          activityPatterns[name] = [];
        }
        activityPatterns[name]!.add(activity);
      }
      
      // Show top repeated activities
      final sortedPatterns = activityPatterns.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
      
      for (final pattern in sortedPatterns.take(3)) {
        buffer.writeln("• ${pattern.key}: ${pattern.value.length} times");
      }
      buffer.writeln();
    }

    if (statistics != null) {
      buffer.writeln("OVERALL STATISTICS:");
      buffer.writeln("• Total time tracked: ${statistics['total_duration_minutes'] ?? 0} minutes");
      buffer.writeln("• Total activities logged: ${statistics['total_activities'] ?? 0}");
      buffer.writeln("• Average duration per activity: ${statistics['average_duration_minutes'] ?? 0} minutes");
      buffer.writeln();
    }

    buffer.writeln("""
RESPONSE FORMAT (return valid JSON only):
{
  "insights": [
    {
      "title": "Concise insight title (max 30 chars)",
      "message": "Specific, actionable message referencing actual activities (max 80 chars)", 
      "category": "balance|progress|achievement|focus|reflection",
      "valueName": "name of the primary value this insight relates to"
    }
  ]
}

GUIDELINES:
- Reference specific activities the user has logged (e.g., "Your 'Morning jog' sessions are consistent - try adding evening walks too")
- Suggest concrete next actions based on their activity patterns (e.g., "Try extending your 'Reading' sessions to 45 minutes")
- Use encouraging, friendly tone (casual but not overly informal)
- Focus on actionable advice that builds on what they're already doing
- Highlight activity patterns and suggest variations or improvements
- Consider the balance between stated importance vs actual time spent
- Categories: balance (aligned), progress (building habits), achievement (milestones), focus (spending more time), reflection (spending less time)
- Keep titles under 30 characters and messages under 80 characters
- Make insights feel personal by mentioning their specific activities by name
- If they repeat activities, acknowledge the consistency and suggest enhancements
- If they're inconsistent, suggest specific ways to build better habits

Respond with JSON only, no other text.
""");

    return buffer.toString();
  }

  /// Parse the AI response and convert to ValueInsight objects
  List<ValueInsight> _parseAIResponse(
    String aiResponse,
    List<ValueModel> values,
    Map<String, Map<String, dynamic>> activityData, [
    List<Map<String, dynamic>>? individualActivities,
  ]) {
    try {
      // Clean the response to extract JSON
      String cleanResponse = aiResponse.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();

      final jsonResponse = json.decode(cleanResponse);
      final List<dynamic> insightsList = jsonResponse['insights'] ?? [];

      final List<ValueInsight> insights = [];

      for (final insightData in insightsList) {
        if (insightData is Map<String, dynamic>) {
          // Find the corresponding value for color
          ValueModel? relatedValue;
          final valueName = insightData['valueName'] as String?;
          if (valueName != null) {
            relatedValue = values.firstWhere(
              (v) => v.name.toLowerCase() == valueName.toLowerCase(),
              orElse: () => values.first,
            );
          }

          // Parse category
          InsightCategory category = InsightCategory.reflection;
          final categoryStr = insightData['category'] as String?;
          if (categoryStr != null) {
            switch (categoryStr.toLowerCase()) {
              case 'balance':
                category = InsightCategory.balance;
                break;
              case 'progress':
                category = InsightCategory.progress;
                break;
              case 'achievement':
                category = InsightCategory.achievement;
                break;
              case 'focus':
                category = InsightCategory.focus;
                break;
              case 'reflection':
                category = InsightCategory.reflection;
                break;
            }
          }

          insights.add(ValueInsight(
            title: (insightData['title'] as String? ?? 'insight').take(30),
            message: (insightData['message'] as String? ?? 'Keep up the great work!').take(80),
            color: relatedValue != null 
                ? Color(int.parse(relatedValue.color.substring(1), radix: 16) + 0xFF000000)
                : const Color(0xFF6C38D4),
            category: category,
            data: {
              'valueName': insightData['valueName'] as String? ?? relatedValue?.name,
            },
          ));
        }
      }

      return insights.isEmpty ? _generateFallbackInsights(values, activityData, individualActivities) : insights;
    } catch (e) {
      developer.log('Failed to parse AI response: $e');
      return _generateFallbackInsights(values, activityData, individualActivities);
    }
  }

  /// Generate fallback insights using the existing conditional logic
  List<ValueInsight> _generateFallbackInsights(
    List<ValueModel> values,
    Map<String, Map<String, dynamic>> activityData, [
    List<Map<String, dynamic>>? individualActivities,
  ]) {
    final List<ValueInsight> insights = [];

    if (values.isEmpty) {
      return [
        const ValueInsight(
          title: "get started",
          message: "add some values and we'll give you super helpful advice!",
          color: Color(0xFF6C38D4),
          category: InsightCategory.reflection,
        )
      ];
    }

    // Find most and least aligned values for fallback insight
    ValueModel? mostAligned;
    ValueModel? leastAligned;
    double mostAlignedDiff = double.infinity;
    double leastAlignedDiff = -1;

    for (final value in values) {
      final activity = activityData[value.name];
      if (activity != null) {
        final minutes = activity['minutes'] as int;
        final communityAvg = activity['community_avg'] as int;

        final statedImportancePercent = (value.importance / 5) * 100;
        final actualBehaviorPercent = (minutes / communityAvg) * 100;
        final difference = (actualBehaviorPercent - statedImportancePercent).abs();

        if (difference < mostAlignedDiff) {
          mostAlignedDiff = difference;
          mostAligned = value;
        }

        if (difference > leastAlignedDiff) {
          leastAlignedDiff = difference;
          leastAligned = value;
        }
      }
    }

    // Generate basic fallback insights
    if (mostAligned != null) {
      insights.add(ValueInsight(
        title: "good balance: ${mostAligned.name}",
        message: "your actions align well with this value",
        color: Color(int.parse(mostAligned.color.substring(1), radix: 16) + 0xFF000000),
        category: InsightCategory.balance,
      ));
    }

    if (leastAligned != null && leastAligned != mostAligned) {
      final activity = activityData[leastAligned.name];
      if (activity != null) {
        final minutes = activity['minutes'] as int;
        final communityAvg = activity['community_avg'] as int;

        // Try to make fallback insights more specific if we have individual activities
        String specificMessage;
        if (individualActivities != null && individualActivities.isNotEmpty) {
          final valueId = leastAligned.id;
          if (valueId != null) {
            // Find activities for this value
            final valueActivities = individualActivities
                .where((act) => act['value_id'] == valueId)
                .toList();
          
            if (valueActivities.isNotEmpty) {
              final mostRecentActivity = valueActivities.first['name'] as String;
              if (minutes < communityAvg) {
                specificMessage = "try doing more '$mostRecentActivity' sessions this week";
              } else {
                specificMessage = "your '$mostRecentActivity' habit is strong - well done!";
              }
            } else {
              specificMessage = minutes < communityAvg 
                  ? "consider spending more time on this important value"
                  : "you're investing lots of time here";
            }
          } else {
            specificMessage = minutes < communityAvg 
                ? "consider spending more time on this important value"
                : "you're investing lots of time here";
          }
        } else {
          specificMessage = minutes < communityAvg 
              ? "consider spending more time on this important value"
              : "you're investing lots of time here";
        }

        if (minutes < communityAvg) {
          insights.add(ValueInsight(
            title: "opportunity: ${leastAligned.name}",
            message: specificMessage,
            color: Color(int.parse(leastAligned.color.substring(1), radix: 16) + 0xFF000000),
            category: InsightCategory.reflection,
          ));
        } else {
          insights.add(ValueInsight(
            title: "deep focus: ${leastAligned.name}",
            message: specificMessage,
            color: Color(int.parse(leastAligned.color.substring(1), radix: 16) + 0xFF000000),
            category: InsightCategory.focus,
          ));
        }
      }
    }

    return insights.isEmpty ? [
      const ValueInsight(
        title: "keep tracking",
        message: "log some activities and we'll give you great insights!",
        color: Color(0xFF6C38D4),
        category: InsightCategory.progress,
      )
    ] : insights;
  }

  /// Generate specific actionable advice for a single value
  Future<String> generateSpecificActionableAdvice({
    required ValueModel value,
    required Map<String, dynamic> activityData,
    required String timeframe,
    required List<Map<String, dynamic>> recentActivities,
  }) async {
    if (!_isInitialized || _model == null) {
      return _generateFallbackAdvice(value, activityData, recentActivities);
    }

    try {
      final prompt = _buildActionableAdvicePrompt(value, activityData, timeframe, recentActivities);
      
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]);

      if (response.text != null) {
        return response.text!.trim();
      } else {
        developer.log('AI response was null for actionable advice');
        return _generateFallbackAdvice(value, activityData, recentActivities);
      }
    } catch (e) {
      developer.log('Actionable advice AI generation failed: $e');
      return _generateFallbackAdvice(value, activityData, recentActivities);
    }
  }

  /// Build a prompt specifically for a single value
  String _buildValueSpecificPrompt(
    ValueModel value,
    Map<String, dynamic> activityData,
    String timeframe,
    List<Map<String, dynamic>> recentActivities,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln("""
You are a personal values alignment coach focusing on a specific value. Generate 3-4 detailed, actionable insights for this value based on the user's $timeframe progress.

TARGET VALUE: ${value.name}
- Stated Importance: ${value.importance}/5
- Time Spent: ${activityData['minutes'] ?? 0} minutes
- Community Average: ${activityData['community_avg'] ?? 60} minutes
""");

    if (recentActivities.isNotEmpty) {
      buffer.writeln("RECENT ACTIVITIES FOR THIS VALUE:");
      
      // Group activities by name to show patterns
      final Map<String, List<Map<String, dynamic>>> activityGroups = {};
      for (final activity in recentActivities.take(10)) {
        final name = activity['name'] as String;
        if (!activityGroups.containsKey(name)) {
          activityGroups[name] = [];
        }
        activityGroups[name]!.add(activity);
      }
      
      for (final group in activityGroups.entries) {
        final totalDuration = group.value.fold<int>(0, (sum, act) => sum + (act['duration'] as int));
        buffer.writeln("• ${group.key}: ${group.value.length} times, $totalDuration total minutes");
        
        // Show notes from recent sessions
        final recentWithNotes = group.value
            .where((act) => act['notes'] != null && act['notes'].toString().isNotEmpty)
            .take(2);
        for (final activity in recentWithNotes) {
          buffer.writeln("  Notes: ${activity['notes']}");
        }
      }
      buffer.writeln();
    }

    buffer.writeln("""
RESPONSE FORMAT (return valid JSON only):
{
  "insights": [
    {
      "title": "Specific insight title (max 30 chars)",
      "message": "Detailed, actionable message referencing specific activities (max 80 chars)", 
      "category": "balance|progress|achievement|focus|reflection",
      "valueName": "${value.name}"
    }
  ]
}

GUIDELINES:
- Focus ONLY on the "${value.name}" value
- Reference specific activities by name (e.g., "Your 'Morning jog' consistency is excellent")
- Suggest concrete improvements or next steps for this specific value
- Consider activity patterns, frequency, and duration trends
- If they're consistent, suggest ways to enhance or expand their practice
- If they're inconsistent, suggest specific strategies to build better habits
- Reference their notes and feedback when available
- Make insights feel personal and specific to their "${value.name}" journey
- Categories: balance (time matches importance), progress (building habits), achievement (milestones), focus (lots of time), reflection (needs more attention)

Respond with JSON only, no other text.
""");

    return buffer.toString();
  }

  /// Generate fallback insights for a specific value
  List<ValueInsight> _generateValueSpecificFallbackInsights(
    ValueModel value,
    Map<String, dynamic> activityData,
    List<Map<String, dynamic>> recentActivities,
  ) {
    final List<ValueInsight> insights = [];
    final valueColor = Color(int.parse(value.color.substring(1), radix: 16) + 0xFF000000);
    final minutes = activityData['minutes'] as int? ?? 0;
    final communityAvg = activityData['community_avg'] as int? ?? 60;

    // Activity frequency insight
    if (recentActivities.isNotEmpty) {
      final activityNames = recentActivities.map((a) => a['name'] as String).toSet();
      if (activityNames.length == 1) {
        final activityName = activityNames.first;
        insights.add(ValueInsight(
          title: "focused on '$activityName'",
          message: "${recentActivities.length} sessions - try mixing in variety",
          color: valueColor,
          category: InsightCategory.progress,
        ));
      } else {
        insights.add(ValueInsight(
          title: "good variety",
          message: "${activityNames.length} different activities - great balance!",
          color: valueColor,
          category: InsightCategory.balance,
        ));
      }
    }

    // Time alignment insight
    final statedPercent = (value.importance / 5) * 100;
    final actualPercent = (minutes / communityAvg) * 100;
    final difference = (actualPercent - statedPercent).abs();

    if (difference <= 20) {
      insights.add(ValueInsight(
        title: "well aligned",
        message: "time spent matches stated importance perfectly",
        color: valueColor,
        category: InsightCategory.balance,
      ));
    } else if (actualPercent > statedPercent) {
      insights.add(ValueInsight(
        title: "high investment",
        message: "you're spending more time than expected - is it worthwhile?",
        color: valueColor,
        category: InsightCategory.focus,
      ));
    } else {
      insights.add(ValueInsight(
        title: "room to grow",
        message: "consider increasing time to match your stated importance",
        color: valueColor,
        category: InsightCategory.reflection,
      ));
    }

    // Recent activity pattern insight
    if (recentActivities.length >= 3) {
      final recentDates = recentActivities
          .map((a) => DateTime.parse(a['date']))
          .toList()..sort();
      
      final daysDiff = recentDates.last.difference(recentDates.first).inDays;
      if (daysDiff <= 7 && recentActivities.length >= 5) {
        insights.add(ValueInsight(
          title: "strong momentum",
          message: "${recentActivities.length} activities this week - keep it up!",
          color: valueColor,
          category: InsightCategory.achievement,
        ));
      }
    }

    return insights.isNotEmpty ? insights : [
      ValueInsight(
        title: "get started",
        message: "log some activities for personalized insights",
        color: valueColor,
        category: InsightCategory.reflection,
      )
    ];
  }

  /// Build a prompt for specific actionable advice
  String _buildActionableAdvicePrompt(
    ValueModel value,
    Map<String, dynamic> activityData,
    String timeframe,
    List<Map<String, dynamic>> recentActivities,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln("""
You are a personal coach providing specific, actionable advice for someone's "${value.name}" value.

VALUE CONTEXT:
- Value: ${value.name}
- Importance Level: ${value.importance}/5
- Time Spent: ${activityData['minutes'] ?? 0} minutes this $timeframe
- Community Average: ${activityData['community_avg'] ?? 60} minutes
""");

    if (recentActivities.isNotEmpty) {
      buffer.writeln("RECENT ACTIVITIES:");
      for (final activity in recentActivities.take(5)) {
        buffer.writeln("• ${activity['name']} (${activity['duration']} mins)");
        if (activity['notes'] != null && activity['notes'].toString().isNotEmpty) {
          buffer.writeln("  Notes: ${activity['notes']}");
        }
      }
      buffer.writeln();
    }

    final valueLower = value.name.toLowerCase();
    String specificPrompt = "";
    
    // Generate value-specific prompts
    if (valueLower.contains('health') || valueLower.contains('fitness') || valueLower.contains('exercise')) {
      specificPrompt = """
Give specific health/fitness advice like:
- Exact foods to eat (e.g., "Try adding salmon twice a week for omega-3s")
- Specific exercises (e.g., "Add 20 push-ups every morning")  
- Measurable goals (e.g., "Aim for 8,000 steps daily" or "Drink 64oz of water")
- Specific distances or times (e.g., "Run 2 miles" or "15-minute meditation")
""";
    } else if (valueLower.contains('reading') || valueLower.contains('learning') || valueLower.contains('education')) {
      specificPrompt = """
Give specific reading/learning advice like:
- Exact book recommendations (e.g., "Read 'Atomic Habits' by James Clear")
- Specific learning goals (e.g., "Learn 5 new vocabulary words daily")
- Reading schedules (e.g., "Read for 30 minutes before bed")
- Learning platforms or courses to try
""";
    } else if (valueLower.contains('social') || valueLower.contains('relationship') || valueLower.contains('friend') || valueLower.contains('family')) {
      specificPrompt = """
Give specific social/relationship advice like:
- Conversation starters (e.g., "Ask about their weekend plans")
- Social activities to try (e.g., "Invite a friend for coffee this week")
- Communication techniques (e.g., "Practice active listening for 5 minutes")
- Specific ways to connect (e.g., "Send one thoughtful text daily")
""";
    } else if (valueLower.contains('work') || valueLower.contains('career') || valueLower.contains('professional')) {
      specificPrompt = """
Give specific career/work advice like:
- Skill development goals (e.g., "Complete one online course this month")
- Networking actions (e.g., "Reach out to 2 colleagues on LinkedIn")
- Productivity techniques (e.g., "Use Pomodoro timer for focused work")
- Specific projects or certifications to pursue
""";
    } else if (valueLower.contains('creative') || valueLower.contains('art') || valueLower.contains('music') || valueLower.contains('writing')) {
      specificPrompt = """
Give specific creative advice like:
- Daily creative practices (e.g., "Sketch for 15 minutes each morning")
- Specific projects to start (e.g., "Write a 500-word story this week")
- Creative challenges (e.g., "Take one photo daily for a week")
- Skills to practice (e.g., "Learn 3 new guitar chords")
""";
    } else {
      specificPrompt = """
Give specific, actionable advice related to "${value.name}" including:
- Concrete steps they can take this week
- Measurable goals or targets
- Specific tools, resources, or techniques to try
- Exact time commitments or schedules
""";
    }

    buffer.writeln(specificPrompt);
    buffer.writeln("""

RESPONSE GUIDELINES:
- Write 2-3 sentences maximum
- Be extremely specific and actionable
- Include numbers, names, or measurable goals when possible  
- Reference their current activities if relevant
- Focus on what they can do THIS WEEK
- Use encouraging, motivational tone
- No generic advice - make it personal and specific

Respond with the advice directly, no formatting or extra text.
""");

    return buffer.toString();
  }

  /// Generate fallback advice when AI is unavailable
  String _generateFallbackAdvice(
    ValueModel value,
    Map<String, dynamic> activityData,
    List<Map<String, dynamic>> recentActivities,
  ) {
    final minutes = activityData['minutes'] as int? ?? 0;
    final valueLower = value.name.toLowerCase();

    // Generate specific fallback advice based on value type
    if (valueLower.contains('health') || valueLower.contains('fitness')) {
      if (recentActivities.isNotEmpty) {
        final mostCommon = _getMostCommonActivity(recentActivities);
        return "Great job with your $mostCommon sessions! Try adding 5 more minutes to each workout and aim for one extra session this week. Consider adding some protein-rich snacks like Greek yogurt or almonds to fuel your progress.";
      }
      return "Start with a 20-minute walk daily and drink an extra glass of water with each meal. Small, consistent steps build lasting healthy habits.";
    } 
    
    if (valueLower.contains('reading') || valueLower.contains('learning')) {
      if (recentActivities.isNotEmpty) {
        return "You're building a great reading habit! Try setting a goal to read 10 pages daily, or explore a new genre this week. Consider keeping a reading journal to track insights.";
      }
      return "Start with just 15 minutes of reading before bed. Pick a book you're genuinely curious about - fiction or non-fiction. The key is consistency over quantity.";
    }
    
    if (valueLower.contains('social') || valueLower.contains('relationship')) {
      return "Try reaching out to one friend or family member this week with a genuine question about their life. Listen actively and ask follow-up questions. Consider scheduling a coffee date or phone call.";
    }
    
    if (valueLower.contains('work') || valueLower.contains('career')) {
      return "Set aside 30 minutes this week to learn one new skill related to your field. This could be watching a tutorial, reading an industry article, or practicing a tool you want to improve with.";
    }

    // Generic fallback
    final timeAdvice = minutes < 60 
        ? "Try dedicating 15-20 minutes daily to ${value.name.toLowerCase()}."
        : "You're spending good time on ${value.name.toLowerCase()}! Consider setting specific weekly goals to maximize impact.";
    
    return "$timeAdvice Focus on one small, consistent action you can take every day. Progress comes from showing up regularly, not from perfect sessions.";
  }

  String _getMostCommonActivity(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return "activity";
    
    final activityCounts = <String, int>{};
    for (final activity in activities) {
      final name = activity['name'] as String;
      activityCounts[name] = (activityCounts[name] ?? 0) + 1;
    }
    
    return activityCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

// Extension to truncate strings safely
extension StringTruncate on String {
  String take(int length) {
    return this.length <= length ? this : '${substring(0, length - 1)}…';
  }
}