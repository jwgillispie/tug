// lib/services/ai_counselor_service.dart
// AI-powered counseling service using Firebase Vertex AI Gemini for vices support

import 'dart:developer' as developer;
import 'package:firebase_ai/firebase_ai.dart';
import '../models/vice_model.dart';

class AICounselorService {
  static final AICounselorService _instance = AICounselorService._internal();
  factory AICounselorService() => _instance;
  AICounselorService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  /// Initialize the Firebase AI model
  Future<void> initialize() async {
    try {
      // For now, disable AI initialization and use fallback mode
      // The Firebase AI setup requires additional configuration
      developer.log('AI Counselor Service temporarily using fallback mode');
      _isInitialized = false; // Force fallback for now
    } catch (e) {
      developer.log('Failed to initialize AI Counselor Service: $e');
      _isInitialized = false;
    }
  }

  /// Generate a counseling response based on user message and their vices context
  Future<String> generateCounselingResponse({
    required String userMessage,
    required List<ViceModel> userVices,
    required List<String> conversationHistory,
  }) async {
    if (!_isInitialized || _model == null) {
      return _generateFallbackResponse(userMessage);
    }

    try {
      final prompt = _buildCounselingPrompt(userMessage, userVices, conversationHistory);
      
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]);

      if (response.text != null && response.text!.trim().isNotEmpty) {
        final cleanResponse = response.text!.trim();
        developer.log('AI Counselor generated response successfully');
        return cleanResponse;
      } else {
        developer.log('AI response was empty, using fallback');
        return _generateFallbackResponse(userMessage);
      }
    } catch (e) {
      developer.log('AI counseling response generation failed: $e');
      return _generateFallbackResponse(userMessage);
    }
  }

  /// Build a comprehensive counseling prompt
  String _buildCounselingPrompt(
    String userMessage,
    List<ViceModel> userVices,
    List<String> conversationHistory,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln("""
You are a compassionate, professional AI counselor specializing in helping people overcome vices and build healthier habits. Your role is to provide supportive, non-judgmental guidance while being warm and understanding.

COUNSELING PRINCIPLES:
- Be empathetic and non-judgmental
- Focus on progress, not perfection
- Provide practical, actionable strategies
- Acknowledge struggles without minimizing them
- Encourage self-compassion and resilience
- Never provide medical advice or diagnose conditions
- Maintain appropriate professional boundaries

USER'S CURRENT VICES:""");

    if (userVices.isNotEmpty) {
      for (final vice in userVices) {
        buffer.writeln("• ${vice.name}:");
        buffer.writeln("  - Current streak: ${vice.currentStreak} days clean");
        buffer.writeln("  - Longest streak: ${vice.longestStreak} days");
        buffer.writeln("  - Total indulgences: ${vice.totalIndulgences}");
        if (vice.description.isNotEmpty) {
          buffer.writeln("  - Notes: ${vice.description}");
        }
      }
    } else {
      buffer.writeln("• No specific vices currently being tracked");
    }

    buffer.writeln();

    if (conversationHistory.isNotEmpty) {
      buffer.writeln("RECENT CONVERSATION CONTEXT:");
      // Include last few messages for context
      final recentHistory = conversationHistory.take(6).toList();
      for (int i = 0; i < recentHistory.length; i++) {
        final isUser = i % 2 == 0; // Assuming alternating user/AI messages
        final speaker = isUser ? "User" : "Counselor";
        buffer.writeln("$speaker: ${recentHistory[i]}");
      }
      buffer.writeln();
    }

    buffer.writeln("CURRENT USER MESSAGE:");
    buffer.writeln("\"$userMessage\"");
    buffer.writeln();

    buffer.writeln("""
RESPONSE GUIDELINES:
- Keep responses to 2-4 sentences for better readability
- Be conversational and warm, not clinical
- Provide specific, actionable advice when appropriate
- Ask thoughtful follow-up questions to encourage reflection
- Reference their specific vices and progress when relevant
- Use encouraging language that promotes hope and self-efficacy
- If they mention crisis situations, acknowledge the severity and suggest professional help
- Focus on small, achievable steps rather than overwhelming goals
- Validate their experiences and feelings
- Offer practical coping strategies for cravings, triggers, and setbacks

COPING STRATEGIES TO REFERENCE:
- Grounding techniques (5-4-3-2-1 sensory method)
- Deep breathing exercises
- Physical movement or exercise
- Calling a friend or support person
- Journaling or writing out feelings
- Mindfulness and meditation
- Distraction activities
- Environmental changes
- Routine establishment
- Self-compassion practices

RESPONSE TONE:
- Supportive and understanding
- Professional but warm
- Non-judgmental and accepting
- Hopeful and encouraging
- Practical and solution-focused

Remember: You're here to support their journey, not to fix them. Every small step forward is worth celebrating.

Respond as the counselor directly, no formatting or prefixes:""");

    return buffer.toString();
  }

  /// Generate fallback responses when AI is unavailable
  String _generateFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Crisis-related keywords
    if (message.contains('hurt') || message.contains('harm') || message.contains('suicidal') || message.contains('kill')) {
      return "I'm concerned about what you're sharing. Please reach out to a crisis helpline or mental health professional immediately - they're trained to help with these feelings. In the US, you can call 988 for the Suicide & Crisis Lifeline. Your life has value, and support is available.";
    }
    
    // Craving-related responses
    if (message.contains('craving') || message.contains('urge') || message.contains('want to')) {
      return "Cravings are a normal part of recovery, and they will pass. Try the 5-4-3-2-1 technique: name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, and 1 you can taste. This helps ground you in the present moment. How are you feeling right now besides the craving?";
    }
    
    // Relapse-related responses
    if (message.contains('relapse') || message.contains('gave in') || message.contains('messed up') || message.contains('failed')) {
      return "A setback doesn't erase all your progress - those clean days still happened and still matter. What's important now is getting back on track. Can you identify what might have triggered this moment? Understanding your patterns helps build stronger defenses for next time.";
    }
    
    // Stress and anxiety responses
    if (message.contains('stress') || message.contains('anxious') || message.contains('overwhelmed') || message.contains('panic')) {
      return "Stress can be a powerful trigger, and it sounds like you're dealing with a lot right now. Try taking three slow, deep breaths with me. Sometimes when we're overwhelmed, our vices feel like the only relief, but there are other ways to cope. What's one small thing that usually helps you feel calmer?";
    }
    
    // Motivation and purpose
    if (message.contains('why') || message.contains('motivation') || message.contains('point') || message.contains('give up')) {
      return "It's natural to question your motivation sometimes - that shows you're human, not weak. Remember why you started this journey. What were your original hopes for how life would improve? Those reasons are still valid, even when the path feels difficult. What's one small thing that's gotten better since you started?";
    }
    
    // Loneliness and isolation
    if (message.contains('alone') || message.contains('lonely') || message.contains('nobody') || message.contains('isolated')) {
      return "Feeling alone in this struggle is really hard, but you're not as alone as it might feel right now. Many people are working through similar challenges. Have you considered connecting with others who understand what you're going through? Sometimes just knowing others 'get it' can make a big difference.";
    }
    
    // Progress and celebration
    if (message.contains('days') || message.contains('streak') || message.contains('clean') || message.contains('sober')) {
      return "Every day you choose differently is an achievement worth acknowledging. Progress isn't always linear, and that's completely normal. What feels different about this time compared to when you first started? Sometimes we don't notice the subtle positive changes happening in ourselves.";
    }
    
    // General supportive response
    return "Thank you for sharing that with me. It takes courage to talk about these challenges, and reaching out shows real strength. Everyone's journey is different, and there's no 'right' way to work through these experiences. What feels most important for you to focus on right now?";
  }

  /// Get personalized coping strategies based on user's vices
  Future<String> generateCopingStrategies({
    required List<ViceModel> userVices,
    required String specificTrigger,
  }) async {
    if (!_isInitialized || _model == null) {
      return _generateFallbackCopingStrategies(specificTrigger);
    }

    try {
      final prompt = _buildCopingStrategiesPrompt(userVices, specificTrigger);
      
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]);

      if (response.text != null && response.text!.trim().isNotEmpty) {
        return response.text!.trim();
      } else {
        return _generateFallbackCopingStrategies(specificTrigger);
      }
    } catch (e) {
      developer.log('Coping strategies generation failed: $e');
      return _generateFallbackCopingStrategies(specificTrigger);
    }
  }

  String _buildCopingStrategiesPrompt(List<ViceModel> userVices, String trigger) {
    final buffer = StringBuffer();
    
    buffer.writeln("""
Generate 3-4 specific, practical coping strategies for someone dealing with this trigger: "$trigger"

Their current vices being tracked:""");

    for (final vice in userVices) {
      buffer.writeln("• ${vice.name} (${vice.currentStreak} days clean)");
    }

    buffer.writeln("""

Provide immediate, actionable strategies they can use right now. Include:
- Physical techniques (breathing, movement, etc.)
- Mental/cognitive strategies
- Environmental changes
- Social support options

Keep each strategy to 1-2 sentences and make them specific enough to act on immediately.
Format as a numbered list.""");

    return buffer.toString();
  }

  String _generateFallbackCopingStrategies(String trigger) {
    return """Here are some strategies you can try right now:

1. **Grounding technique**: Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, and 1 you can taste to bring yourself into the present moment.

2. **Change your environment**: Step outside, move to a different room, or change your physical position to interrupt the trigger pattern.

3. **Reach out**: Call or text someone you trust, even if it's just to say "thinking of you" - connection can shift your mindset.

4. **Physical release**: Do 10 jumping jacks, push-ups, or take a quick walk to release tension and redirect energy.

Remember, cravings are temporary but your progress is real. You've made it this far, and that shows your strength.""";
  }

  /// Generate a personalized affirmation based on user's vices
  Future<String> generatePersonalizedAffirmation({
    required List<ViceModel> userVices,
  }) async {
    if (!_isInitialized || _model == null) {
      return _generateFallbackAffirmation(userVices);
    }

    try {
      final prompt = _buildAffirmationPrompt(userVices);
      
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]);

      if (response.text != null && response.text!.trim().isNotEmpty) {
        final cleanResponse = response.text!.trim();
        developer.log('AI Counselor generated affirmation successfully');
        return cleanResponse;
      } else {
        developer.log('AI affirmation response was empty, using fallback');
        return _generateFallbackAffirmation(userVices);
      }
    } catch (e) {
      developer.log('AI affirmation generation failed: $e');
      return _generateFallbackAffirmation(userVices);
    }
  }

  /// Build a prompt for generating personalized affirmations
  String _buildAffirmationPrompt(List<ViceModel> userVices) {
    final buffer = StringBuffer();
    
    buffer.writeln("""
Create a meaningful, personalized affirmation for someone working to overcome their vices. Make it deeply motivational and specific to their journey.

USER'S VICES:""");

    if (userVices.isNotEmpty) {
      for (final vice in userVices) {
        buffer.writeln("• ${vice.name}:");
        buffer.writeln("  - Current streak: ${vice.currentStreak} days clean");
        buffer.writeln("  - Longest streak: ${vice.longestStreak} days");
        if (vice.description.isNotEmpty) {
          buffer.writeln("  - Personal notes: ${vice.description}");
        }
      }
    } else {
      buffer.writeln("• User is working on general self-improvement");
    }

    buffer.writeln("""

AFFIRMATION GUIDELINES:
- Make it personal and specific to their vices/challenges
- Include their progress and strength they've already shown
- Use powerful, positive language that builds confidence
- Reference their resilience and capability for change
- Keep it to 2-3 sentences maximum
- Make it something they can repeat to themselves daily
- Focus on their inner strength and potential for growth
- Use "I am" statements when possible
- Make it feel authentic and meaningful, not generic

Create a powerful affirmation that acknowledges their specific journey and reinforces their ability to overcome their challenges. Respond with just the affirmation, no other text.""");

    return buffer.toString();
  }

  /// Generate fallback affirmations when AI is unavailable
  String _generateFallbackAffirmation(List<ViceModel> userVices) {
    if (userVices.isEmpty) {
      return "I am stronger than any challenge that comes my way. Every day I choose growth over comfort, I become the person I'm meant to be.";
    }

    // Get the vice with the longest streak for motivation
    final bestVice = userVices.reduce((a, b) => 
        a.longestStreak > b.longestStreak ? a : b);
    
    final viceName = bestVice.name.toLowerCase();
    final streak = bestVice.currentStreak;
    final longestStreak = bestVice.longestStreak;

    if (streak > 0) {
      return "I am proving to myself every day that I am stronger than $viceName. With $streak days of strength behind me, I choose freedom and growth over temporary temptation.";
    } else if (longestStreak > 0) {
      return "I have overcome $viceName for $longestStreak days before, which proves I have the strength within me. Every setback is a setup for an even stronger comeback.";
    } else {
      return "I am taking the brave first steps to overcome $viceName. My journey begins with this moment, and I have everything within me to succeed.";
    }
  }
}