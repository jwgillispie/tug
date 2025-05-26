// Example implementation of the ValueInsights widget
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';
import 'package:tug/widgets/home/value_insights.dart';

class InsightExamples extends StatelessWidget {
  const InsightExamples({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate some example insights
    final insights = [
      ValueInsight(
        title: "Great Balance: Family Time",
        message: "your actions align closely with how much you value family.",
        color: TugColors.primaryPurple,
        category: InsightCategory.balance,
      ),
      ValueInsight(
        title: "New Streak: Exercise",
        message: "You've been consistent with exercise for 5 days!",
        color: TugColors.success,
        category: InsightCategory.progress,
      ),
      ValueInsight(
        title: "Milestone: Learning",
        message: "You've invested 100+ hours in learning this month!",
        color: TugColors.info,
        category: InsightCategory.achievement,
      ),
      ValueInsight(
        title: "Opportunity: Mindfulness",
        message: "Consider more time on mindfulness given its importance.",
        color: TugColors.warning,
        category: InsightCategory.reflection,
      ),
    ];
    
    // Examples with factory methods
    final valueBasedInsights = [
      ValueInsight.fromValue(
        valueName: "Family",
        statedImportance: 5, // 1-5 scale
        actualMinutes: 240, // Minutes per day
        averageMinutes: 120, // Community average
        valueColor: TugColors.primaryPurple,
      ),
      ValueInsight.fromValue(
        valueName: "Career",
        statedImportance: 4,
        actualMinutes: 480,
        averageMinutes: 300,
        valueColor: TugColors.info, 
      ),
      ValueInsight.fromValue(
        valueName: "Health",
        statedImportance: 5,
        actualMinutes: 60,
        averageMinutes: 90,
        valueColor: TugColors.success,
      ),
    ];
    
    final streakInsights = [
      ValueInsight.fromStreak(
        valueName: "Meditation",
        streakDays: 42,
        valueColor: TugColors.primaryPurpleLight,
      ),
      ValueInsight.fromStreak(
        valueName: "Reading",
        streakDays: 12,
        valueColor: TugColors.warning,
      ),
    ];
    
    // Combine all insights (in a real app, you would choose which to display)
    final allInsights = [...insights, ...valueBasedInsights, ...streakInsights];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Text(
            "Value Insights",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ValueInsights(
          insights: allInsights,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Insight tapped! Could navigate to detailed view."),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}