# app/services/coaching_template_service.py
import logging
from typing import List, Dict, Any
from datetime import datetime

from ..models.coaching_message import (
    CoachingMessageTemplate, CoachingMessageType, CoachingMessageTone, 
    CoachingMessagePriority
)

logger = logging.getLogger(__name__)

class CoachingTemplateService:
    """Service for managing coaching message templates"""
    
    def __init__(self):
        self.default_templates = self._create_default_templates()
    
    async def seed_default_templates(self) -> int:
        """Seed the database with default coaching message templates"""
        
        try:
            seeded_count = 0
            
            for template_data in self.default_templates:
                # Check if template already exists
                existing = await CoachingMessageTemplate.find_one({
                    "template_id": template_data["template_id"]
                })
                
                if not existing:
                    template = CoachingMessageTemplate(**template_data)
                    await template.save()
                    seeded_count += 1
                    logger.info(f"Seeded template: {template_data['template_id']}")
            
            logger.info(f"Seeded {seeded_count} coaching message templates")
            return seeded_count
            
        except Exception as e:
            logger.error(f"Error seeding coaching templates: {e}", exc_info=True)
            return 0
    
    def _create_default_templates(self) -> List[Dict[str, Any]]:
        """Create default coaching message templates"""
        
        templates = []
        
        # ==================
        # PROGRESS ENCOURAGEMENT TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "progress_consistency_recognition",
                "message_type": CoachingMessageType.PROGRESS_ENCOURAGEMENT,
                "name": "Consistency Recognition",
                "description": "Recognize user's consistent effort and progress",
                "title_template": "Your consistency is paying off, {user_first_name}! 🌟",
                "message_template": "You've logged {recent_activity_count} activities this week with {consistency_this_week} days of practice. Your dedication to growth is inspiring! Every small step is building toward something amazing.",
                "action_text_template": "Keep Building",
                "tone": CoachingMessageTone.ENCOURAGING,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 7,
                "min_activity_count": 5,
                "cooldown_hours": 48,
                "expiry_hours": 72,
                "optimal_hours": [9, 18, 20],
                "user_segments": ["Consistency Builder", "Habit Master"]
            },
            {
                "template_id": "progress_momentum_builder",
                "message_type": CoachingMessageType.PROGRESS_ENCOURAGEMENT,
                "name": "Momentum Builder",
                "description": "Encourage users who are building good momentum",
                "title_template": "You're on fire! 🔥",
                "message_template": "Your {formation_probability}% habit formation success rate shows you're really getting the hang of this, {user_first_name}. The momentum you're building now will carry you toward your bigger goals!",
                "action_text_template": "View Progress",
                "tone": CoachingMessageTone.MOTIVATIONAL,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 14,
                "min_activity_count": 10,
                "cooldown_hours": 72,
                "expiry_hours": 48,
                "optimal_hours": [19, 20, 21]
            }
        ])
        
        # ==================
        # MILESTONE CELEBRATION TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "milestone_streak_3_days",
                "message_type": CoachingMessageType.MILESTONE_CELEBRATION,
                "name": "3-Day Streak Celebration",
                "description": "Celebrate 3-day milestone - first major milestone",
                "title_template": "3 days in a row! 🎯",
                "message_template": "Congratulations, {user_first_name}! You've just hit your first major milestone with a 3-day streak. This is where habits start to take root. You're proving to yourself that consistency is possible!",
                "action_text_template": "Keep Going",
                "tone": CoachingMessageTone.CELEBRATORY,
                "priority": CoachingMessagePriority.HIGH,
                "min_user_age_days": 3,
                "min_activity_count": 3,
                "cooldown_hours": 0,  # Always celebrate milestones
                "expiry_hours": 24,
                "optimal_hours": [9, 10, 18, 19],
            },
            {
                "template_id": "milestone_week_achievement",
                "message_type": CoachingMessageType.MILESTONE_CELEBRATION,
                "name": "Week Achievement",
                "description": "Celebrate completing a full week of practice",
                "title_template": "One full week! Amazing! 🏆",
                "message_template": "Seven days of consistent practice, {user_first_name}! You've just proven that you can stick to commitments and build lasting habits. This is the foundation that transforms lives. Incredible work!",
                "action_text_template": "Celebrate",
                "tone": CoachingMessageTone.CELEBRATORY,
                "priority": CoachingMessagePriority.HIGH,
                "min_user_age_days": 7,
                "min_activity_count": 7,
                "cooldown_hours": 0,
                "expiry_hours": 48,
                "optimal_hours": [19, 20]
            },
            {
                "template_id": "milestone_month_mastery",
                "message_type": CoachingMessageType.MILESTONE_CELEBRATION,
                "name": "Month Mastery",
                "description": "Celebrate 30-day achievement - major milestone",
                "title_template": "30 days of dedication! You're a habit master! 🎖️",
                "message_template": "One month of consistent practice, {user_first_name}! You've officially transformed from someone who 'tries' to someone who 'does.' This level of commitment puts you in the top 5% of people who achieve their goals. Exceptional!",
                "action_text_template": "Share Success",
                "tone": CoachingMessageTone.CELEBRATORY,
                "priority": CoachingMessagePriority.URGENT,
                "min_user_age_days": 30,
                "min_activity_count": 25,
                "cooldown_hours": 0,
                "expiry_hours": 72,
                "optimal_hours": [19, 20, 21]
            }
        ])
        
        # ==================
        # STREAK RECOVERY TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "streak_recovery_gentle",
                "message_type": CoachingMessageType.STREAK_RECOVERY,
                "name": "Gentle Recovery",
                "description": "Supportive message for users who broke a short streak",
                "title_template": "Every champion faces setbacks 💪",
                "message_template": "You had a {previous_streak}-day streak going, {user_first_name}. That's not lost - it's proof you can do it! The most successful people aren't those who never fall, but those who get back up quickly. Ready to start again?",
                "action_text_template": "Start Fresh",
                "tone": CoachingMessageTone.SUPPORTIVE,
                "priority": CoachingMessagePriority.HIGH,
                "min_user_age_days": 3,
                "min_activity_count": 3,
                "cooldown_hours": 12,
                "expiry_hours": 48,
                "optimal_hours": [9, 10, 18, 19]
            },
            {
                "template_id": "streak_recovery_motivational",
                "message_type": CoachingMessageType.STREAK_RECOVERY,
                "name": "Motivational Recovery",
                "description": "Motivational message for users ready for a strong comeback",
                "title_template": "Comeback time! Your best streak starts now 🚀",
                "message_template": "You've taken {gap_days} days off, and now you're back, {user_first_name}! This is the moment where champions are made. Your {previous_streak}-day streak proved you have what it takes. Let's build an even stronger one!",
                "action_text_template": "Begin Comeback",
                "tone": CoachingMessageTone.MOTIVATIONAL,
                "priority": CoachingMessagePriority.HIGH,
                "min_user_age_days": 7,
                "min_activity_count": 5,
                "cooldown_hours": 24,
                "expiry_hours": 24,
                "optimal_hours": [8, 9, 18, 19]
            }
        ])
        
        # ==================
        # STREAK RISK WARNING TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "streak_risk_urgent",
                "message_type": CoachingMessageType.STREAK_RISK_WARNING,
                "name": "Urgent Streak Warning",
                "description": "High-priority warning for streaks at immediate risk",
                "title_template": "Don't break the chain! ⚠️",
                "message_template": "Your {current_streak}-day streak is at risk, {user_first_name}! It's been {time_since_last} hours since your last activity. Just 5 minutes can keep your incredible momentum going. You've come too far to stop now!",
                "action_text_template": "Save My Streak",
                "tone": CoachingMessageTone.URGENT,
                "priority": CoachingMessagePriority.URGENT,
                "min_user_age_days": 3,
                "min_activity_count": 3,
                "cooldown_hours": 8,
                "expiry_hours": 12,
                "optimal_hours": [9, 18, 19, 20]
            },
            {
                "template_id": "streak_risk_gentle_reminder",
                "message_type": CoachingMessageType.STREAK_RISK_WARNING,
                "name": "Gentle Reminder",
                "description": "Gentle nudge for early-stage risk",
                "title_template": "Keep your streak alive 🔄",
                "message_template": "Hi {user_first_name}, you're {current_streak} days into building something great! Haven't seen you today yet - even a quick 5-minute session keeps your momentum strong. What can you do right now?",
                "action_text_template": "Quick Session",
                "tone": CoachingMessageTone.GENTLE,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 3,
                "min_activity_count": 3,
                "cooldown_hours": 12,
                "expiry_hours": 8,
                "optimal_hours": [19, 20, 21]
            }
        ])
        
        # ==================
        # CHALLENGE AND GROWTH TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "challenge_next_level",
                "message_type": CoachingMessageType.CHALLENGE_MOTIVATION,
                "name": "Next Level Challenge",
                "description": "Motivate advanced users to take on new challenges",
                "title_template": "Ready for a challenge? 🎯",
                "message_template": "You've mastered consistency, {user_first_name}! Your {user_segment} status shows you're ready for the next level. What if you tried extending your sessions by 10 minutes or adding a second daily practice?",
                "action_text_template": "Accept Challenge",
                "tone": CoachingMessageTone.CHALLENGING,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 21,
                "min_activity_count": 20,
                "cooldown_hours": 72,
                "expiry_hours": 120,
                "optimal_hours": [18, 19, 20],
                "user_segments": ["Habit Master", "Quality Focused", "Consistency Builder"]
            },
            {
                "template_id": "goal_expansion_opportunity",
                "message_type": CoachingMessageType.GOAL_SUGGESTION,
                "name": "Goal Expansion",
                "description": "Suggest expanding to new areas based on success",
                "title_template": "New goal opportunity spotted! 🌱",
                "message_template": "Based on your {formation_probability}% success rate with current habits, you might be ready to expand, {user_first_name}! Consider adding a complementary practice that aligns with your strongest values.",
                "action_text_template": "Explore Goals",
                "tone": CoachingMessageTone.ENCOURAGING,
                "priority": CoachingMessagePriority.LOW,
                "min_user_age_days": 14,
                "min_activity_count": 15,
                "cooldown_hours": 96,
                "expiry_hours": 168,
                "optimal_hours": [19, 20, 21]
            }
        ])
        
        # ==================
        # WISDOM AND TIPS TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "habit_tip_consistency",
                "message_type": CoachingMessageType.HABIT_TIP,
                "name": "Consistency Tip",
                "description": "Share insights about building consistency",
                "title_template": "💡 Habit insight: The power of \"just show up\"",
                "message_template": "Here's what successful habit builders know, {user_first_name}: showing up is 80% of the battle. Even on tough days, doing the minimum version of your practice keeps the neural pathway strong. Quality can fluctuate, but consistency compounds.",
                "action_text_template": "Apply This",
                "tone": CoachingMessageTone.WISE,
                "priority": CoachingMessagePriority.LOW,
                "min_user_age_days": 10,
                "min_activity_count": 8,
                "cooldown_hours": 48,
                "expiry_hours": 96,
                "optimal_hours": [20, 21]
            },
            {
                "template_id": "timing_wisdom",
                "message_type": CoachingMessageType.TIMING_OPTIMIZATION,
                "name": "Optimal Timing Wisdom",
                "description": "Share personalized timing insights",
                "title_template": "🕒 Your peak performance time: {peak_time}",
                "message_template": "Data shows you perform best at {peak_time} on {peak_day}s, {user_first_name}! Your energy and focus align perfectly then. Try scheduling your most important activities during this golden window for maximum impact.",
                "action_text_template": "Optimize Schedule",
                "tone": CoachingMessageTone.WISE,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 14,
                "min_activity_count": 10,
                "cooldown_hours": 168,  # Once per week max
                "expiry_hours": 96,
                "optimal_hours": [19, 20]
            }
        ])
        
        # ==================
        # CONTEXTUAL MOTIVATION TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "morning_fresh_start",
                "message_type": CoachingMessageType.MORNING_MOTIVATION,
                "name": "Fresh Start Morning",
                "description": "Morning motivation for new beginnings",
                "title_template": "Good morning, champion! ☀️",
                "message_template": "A new day, a fresh opportunity to build on your progress, {user_first_name}! Yesterday is behind you, tomorrow isn't here yet - this moment is where your transformation happens. What will you create today?",
                "action_text_template": "Start Day Strong",
                "tone": CoachingMessageTone.MOTIVATIONAL,
                "priority": CoachingMessagePriority.LOW,
                "min_user_age_days": 1,
                "min_activity_count": 1,
                "cooldown_hours": 20,  # Once per day
                "expiry_hours": 6,  # Morning messages expire quickly
                "optimal_hours": [7, 8, 9, 10],
                "avoid_days": []  # Can send any day
            },
            {
                "template_id": "evening_reflection",
                "message_type": CoachingMessageType.EVENING_REFLECTION,
                "name": "Evening Reflection",
                "description": "Evening reflection on the day's progress",
                "title_template": "How did today go? 🌙",
                "message_template": "As your day winds down, {user_first_name}, take a moment to acknowledge what you accomplished. Every step forward, no matter how small, is worth celebrating. You're building something meaningful, one day at a time.",
                "action_text_template": "Reflect",
                "tone": CoachingMessageTone.GENTLE,
                "priority": CoachingMessagePriority.LOW,
                "min_user_age_days": 3,
                "min_activity_count": 3,
                "cooldown_hours": 20,
                "expiry_hours": 4,  # Evening messages expire quickly
                "optimal_hours": [20, 21, 22]
            },
            {
                "template_id": "weekend_encouragement",
                "message_type": CoachingMessageType.WEEKEND_ENCOURAGEMENT,
                "name": "Weekend Encouragement",
                "description": "Weekend-specific motivation and support",
                "title_template": "Weekend warrior mode! 🎯",
                "message_template": "Weekends are where habits are truly tested, {user_first_name}! Without the structure of weekdays, this is when your commitment shines. Use this time to reinforce your practice and maybe even enjoy it a little more.",
                "action_text_template": "Weekend Practice",
                "tone": CoachingMessageTone.ENCOURAGING,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 7,
                "min_activity_count": 5,
                "cooldown_hours": 48,
                "expiry_hours": 48,
                "optimal_hours": [9, 10, 18, 19],
                "avoid_days": [0, 1, 2, 3, 4]  # Only send on weekends (5=Saturday, 6=Sunday)
            }
        ])
        
        # ==================
        # REACTIVATION TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "gentle_reactivation",
                "message_type": CoachingMessageType.REACTIVATION,
                "name": "Gentle Reactivation",
                "description": "Gentle invitation for users who've been away",
                "title_template": "We miss you! 💙",
                "message_template": "Hey {user_first_name}, it's been a while! Life gets busy, and that's completely normal. Your past progress of {total_activities} activities shows you have what it takes. Ready to ease back in? Even 5 minutes counts.",
                "action_text_template": "Ease Back In",
                "tone": CoachingMessageTone.GENTLE,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 7,
                "min_activity_count": 3,
                "cooldown_hours": 72,
                "expiry_hours": 72,
                "optimal_hours": [18, 19, 20]
            },
            {
                "template_id": "motivational_reactivation",
                "message_type": CoachingMessageType.REACTIVATION,
                "name": "Motivational Comeback",
                "description": "Motivational message for ready-to-restart users",
                "title_template": "Your comeback starts now! 🚀",
                "message_template": "The best time to plant a tree was 20 years ago. The second best time is now, {user_first_name}! You've got {total_activities} activities under your belt - that experience isn't lost. It's time to show yourself what you're capable of again!",
                "action_text_template": "Make Comeback",
                "tone": CoachingMessageTone.MOTIVATIONAL,
                "priority": CoachingMessagePriority.HIGH,
                "min_user_age_days": 14,
                "min_activity_count": 10,
                "cooldown_hours": 96,
                "expiry_hours": 48,
                "optimal_hours": [9, 18, 19]
            }
        ])
        
        # ==================
        # USER SEGMENT SPECIFIC TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "habit_master_recognition",
                "message_type": CoachingMessageType.CONSISTENCY_RECOGNITION,
                "name": "Habit Master Recognition",
                "description": "Special recognition for habit masters",
                "title_template": "Habit Master status confirmed! 👑",
                "message_template": "Your consistency and discipline are exceptional, {user_first_name}! As a Habit Master, you're in the top tier of people who not only set goals but achieve them systematically. Your example inspires others to reach higher.",
                "action_text_template": "Share Wisdom",
                "tone": CoachingMessageTone.CELEBRATORY,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 30,
                "min_activity_count": 25,
                "cooldown_hours": 168,  # Once per week
                "expiry_hours": 96,
                "optimal_hours": [19, 20],
                "user_segments": ["Habit Master"],
                "premium_only": False
            },
            {
                "template_id": "getting_started_encouragement",
                "message_type": CoachingMessageType.PROGRESS_ENCOURAGEMENT,
                "name": "Getting Started Encouragement",
                "description": "Encouragement for new users finding their rhythm",
                "title_template": "Every expert was once a beginner 🌱",
                "message_template": "You're in the exploration phase, {user_first_name}, and that's exactly where growth happens! Don't worry about being perfect - focus on being consistent. You're building the foundation for something amazing.",
                "action_text_template": "Keep Exploring",
                "tone": CoachingMessageTone.ENCOURAGING,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 3,
                "min_activity_count": 2,
                "cooldown_hours": 36,
                "expiry_hours": 48,
                "optimal_hours": [9, 18, 19],
                "user_segments": ["Getting Started"]
            }
        ])
        
        # ==================
        # PREMIUM-SPECIFIC TEMPLATES
        # ==================
        
        templates.extend([
            {
                "template_id": "premium_advanced_insights",
                "message_type": CoachingMessageType.BEHAVIORAL_INSIGHT,
                "name": "Premium Advanced Insights",
                "description": "Advanced behavioral insights for premium users",
                "title_template": "🧠 Premium Insight: Your unique pattern",
                "message_template": "Your premium AI analysis shows a fascinating pattern, {user_first_name}: you're {confidence_score}% more likely to succeed when you start at {peak_time}. This kind of personalized insight is your competitive advantage in building lasting habits.",
                "action_text_template": "View Full Analysis",
                "tone": CoachingMessageTone.WISE,
                "priority": CoachingMessagePriority.MEDIUM,
                "min_user_age_days": 14,
                "min_activity_count": 15,
                "cooldown_hours": 96,
                "expiry_hours": 120,
                "optimal_hours": [19, 20, 21],
                "premium_only": True
            }
        ])
        
        return templates