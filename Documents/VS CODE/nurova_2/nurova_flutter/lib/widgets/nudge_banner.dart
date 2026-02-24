import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'glass_card.dart';

class NudgeBanner extends StatefulWidget {
  const NudgeBanner({super.key});

  @override
  State<NudgeBanner> createState() => _NudgeBannerState();
}

class _NudgeBannerState extends State<NudgeBanner> {
  int _nudgeIndex = 0;

  final List<Map<String, dynamic>> _nudges = [
    {
      'emoji': '🧠',
      'text': 'One LeetCode problem = one dopamine hit. Start small.',
      'color': Color(0xFF6C63FF),
    },
    {
      'emoji': '🌬️',
      'text': 'Box breathing: 4s in → 4s hold → 4s out. Reset your focus.',
      'color': Color(0xFF00D4FF),
    },
    {
      'emoji': '⚡',
      'text': 'The Pomodoro is 25 min. You can do anything for 25 minutes.',
      'color': Color(0xFFFFAA00),
    },
    {
      'emoji': '🎯',
      'text': 'What\'s the ONE thing you need to finish today?',
      'color': Color(0xFF00FF88),
    },
    {
      'emoji': '📵',
      'text': 'Put your phone face-down. Watch your focus double.',
      'color': Color(0xFFFF4D6D),
    },
  ];

  @override
  void initState() {
    super.initState();
    _autoRotate();
  }

  void _autoRotate() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) {
        setState(() => _nudgeIndex = (_nudgeIndex + 1) % _nudges.length);
      }
      return mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nudge = _nudges[_nudgeIndex];
    final color = nudge['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _nudgeIndex = (_nudgeIndex + 1) % _nudges.length),
      child: GlassCard(
        borderColor: color.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  nudge['emoji'] as String,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nurova Nudge',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nudge['text'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ).animate(key: ValueKey(_nudgeIndex)).fadeIn(duration: 500.ms),
    );
  }
}
