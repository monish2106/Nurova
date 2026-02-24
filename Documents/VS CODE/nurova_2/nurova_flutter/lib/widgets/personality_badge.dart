import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/prediction_model.dart';
import 'glass_card.dart';

class PersonalityBadge extends StatelessWidget {
  final PersonalityModel personality;

  const PersonalityBadge({super.key, required this.personality});

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientForCluster(personality.cluster);

    return GlassCard(
      borderColor: gradient.colors.first.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    personality.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ).animate().scale(delay: 200.ms, duration: 400.ms),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Personality Type',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      personality.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: personality.traits
                .map((trait) => _traitChip(trait, gradient.colors.first))
                .toList(),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _traitChip(String trait, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        trait,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  LinearGradient _gradientForCluster(String cluster) {
    switch (cluster) {
      case 'NightScrollAddict':
        return const LinearGradient(
            colors: [Color(0xFF4C35DE), Color(0xFF8B5CF6)]);
      case 'StressScroller':
        return const LinearGradient(
            colors: [Color(0xFFFF4D6D), Color(0xFFFF8A65)]);
      case 'ProcrastinationBinger':
        return const LinearGradient(
            colors: [Color(0xFFFFAA00), Color(0xFFFF6B6B)]);
      case 'ProductiveSprinter':
        return const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFF00FF88)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]);
    }
  }
}
