import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../bloc/session_bloc.dart';
import '../bloc/prediction_bloc.dart';
import '../models/prediction_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/personality_badge.dart';
import '../widgets/nudge_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  double _lastRisk = 0.45;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Trigger initial prediction after short delay
    Future.delayed(const Duration(seconds: 2), _fetchPrediction);

    // Auto-refresh every 60 seconds
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 60));
      if (mounted) _fetchPrediction();
      return mounted;
    });
  }

  void _fetchPrediction() {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is SessionRunning) {
      context.read<PredictionBloc>().add(
            FetchPredictionEvent(sessionState.session.toFeatures()),
          );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSessionTimer(),
                const SizedBox(height: 16),
                _buildRiskMeter(),
                const SizedBox(height: 16),
                _buildPersonalitySection(),
                const SizedBox(height: 16),
                _buildNudgeSection(),
                const SizedBox(height: 16),
                _buildQuickStats(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: false,
      backgroundColor: const Color(0xFF0D0D1A),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Nurova 2.0',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSessionTimer() {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final duration = state is SessionRunning
            ? state.session.formattedDuration
            : '0m 0s';
        final screenTime = state is SessionRunning
            ? state.session.screenTimeHours
            : 0.0;

        return GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Session',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Screen Time',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${screenTime.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskMeter() {
    return BlocBuilder<PredictionBloc, PredictionState>(
      builder: (context, state) {
        double risk = 0.45;
        String action = 'MEDIUM_RISK';
        String nudge = '';

        if (state is PredictionLoaded) {
          risk = state.prediction.riskProbability;
          action = state.prediction.action;
          nudge = state.prediction.nudge;

          if (risk != _lastRisk && risk > 0.75) {
            HapticFeedback.heavyImpact();
          }
          _lastRisk = risk;
        }

        final riskColor = _riskColor(risk);

        return GlassCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Distraction Risk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: riskColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      action.replaceAll('_', ' '),
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (risk > 0.75)
                        Container(
                          width: 160 + _pulseController.value * 20,
                          height: 160 + _pulseController.value * 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: riskColor.withOpacity(0.05 * _pulseController.value),
                          ),
                        ),
                      CircularPercentIndicator(
                        radius: 80.0,
                        lineWidth: 14.0,
                        animation: true,
                        animationDuration: 1200,
                        percent: risk,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(risk * 100).round()}%',
                              style: TextStyle(
                                color: riskColor,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _riskLabel(risk),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        progressColor: riskColor,
                        backgroundColor: riskColor.withOpacity(0.1),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ],
                  );
                },
              ),
              if (state is PredictionLoaded && nudge.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    nudge,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 800.ms),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _fetchPrediction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                    foregroundColor: const Color(0xFF6C63FF),
                    side: const BorderSide(color: Color(0xFF6C63FF), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: state is PredictionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Analyze Now',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalitySection() {
    return BlocBuilder<PredictionBloc, PredictionState>(
      builder: (context, state) {
        PersonalityModel? personality;
        if (state is PredictionLoaded) personality = state.personality;

        return personality != null
            ? PersonalityBadge(personality: personality)
            : GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Colors.white54),
                    const SizedBox(width: 12),
                    Text(
                      'Analyzing your personality...',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        final sessionState = context.read<SessionBloc>().state;
                        if (sessionState is SessionRunning) {
                          context.read<PredictionBloc>().add(
                                FetchPersonalityEvent(
                                    [sessionState.session.toFeatures()]),
                              );
                        }
                      },
                      child: const Text('Detect'),
                    ),
                  ],
                ),
              );
      },
    );
  }

  Widget _buildNudgeSection() {
    return const NudgeBanner();
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard('Focus Score', '72%', Icons.track_changes,
              const Color(0xFF00D4FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard('Tasks Done', '4/6', Icons.check_circle_outline,
              const Color(0xFF6C63FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
              'vs Yesterday', '+28%', Icons.trending_up, const Color(0xFF00FF88)),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Color _riskColor(double risk) {
    if (risk > 0.75) return const Color(0xFFFF4D6D);
    if (risk > 0.45) return const Color(0xFFFFAA00);
    return const Color(0xFF00FF88);
  }

  String _riskLabel(double risk) {
    if (risk > 0.75) return 'HIGH RISK';
    if (risk > 0.45) return 'MEDIUM RISK';
    return 'LOW RISK';
  }
}
