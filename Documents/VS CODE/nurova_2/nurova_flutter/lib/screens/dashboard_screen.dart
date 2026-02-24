import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_service.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, dynamic> _dailyStats = {};
  bool _loading = true;

  // Demo data
  final List<double> _riskTrend = [0.65, 0.72, 0.58, 0.81, 0.47, 0.69, 0.87];
  final List<double> _screenTimeTrend = [6.2, 8.1, 5.5, 9.3, 4.8, 7.6, 10.2];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final weekly = await DatabaseService.getWeeklyData();
    final daily = await DatabaseService.getDailyStats();
    setState(() {
      _weeklyData = weekly;
      _dailyStats = daily;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Dashboard'),
            pinned: false,
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSummaryRow(),
                const SizedBox(height: 16),
                _buildRiskTrendChart(),
                const SizedBox(height: 16),
                _buildScreenTimeChart(),
                const SizedBox(height: 16),
                _buildPersonalityDistribution(),
                const SizedBox(height: 16),
                _buildProductivityInsight(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final avgRisk = (_dailyStats['avg_risk'] as num?)?.toDouble() ?? 0.68;
    final screenTime = (_dailyStats['total_screen_time'] as num?)?.toDouble() ?? 7.4;
    final prodScore = (_dailyStats['productivity_score'] as num?)?.toDouble() ?? 0.62;

    return Row(
      children: [
        Expanded(child: _metricCard('Avg Risk', '${(avgRisk * 100).round()}%',
            const Color(0xFFFF4D6D))),
        const SizedBox(width: 12),
        Expanded(child: _metricCard('Screen Time', '${screenTime.toStringAsFixed(1)}h',
            const Color(0xFF00D4FF))),
        const SizedBox(width: 12),
        Expanded(child: _metricCard('Productivity', '${(prodScore * 100).round()}%',
            const Color(0xFF00FF88))),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildRiskTrendChart() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Risk Trend (7 days)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '↑ 12% this week',
                  style: TextStyle(color: Color(0xFFFF4D6D), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _days.length) return const SizedBox();
                        return Text(
                          _days[idx],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Text(
                        '${(val * 100).round()}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                      reservedSize: 36,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: _riskTrend.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFFFF4D6D),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFFFF4D6D),
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF4D6D).withOpacity(0.3),
                          const Color(0xFFFF4D6D).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildScreenTimeChart() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Screen Time (hours)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _days.length) return const SizedBox();
                        return Text(
                          _days[idx],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _screenTimeTrend.asMap().entries.map((e) {
                  final isToday = e.key == 6;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                        color: isToday
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF00D4FF).withOpacity(0.5),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPersonalityDistribution() {
    final types = [
      {'label': 'Night Scroll', 'pct': 0.35, 'color': const Color(0xFF6C63FF)},
      {'label': 'Procrastinator', 'pct': 0.28, 'color': const Color(0xFFFF4D6D)},
      {'label': 'Stress Scroller', 'pct': 0.22, 'color': const Color(0xFFFFAA00)},
      {'label': 'Productive', 'pct': 0.15, 'color': const Color(0xFF00FF88)},
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personality Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on 30-day usage patterns',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ...types.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t['label'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${((t['pct'] as double) * 100).round()}%',
                          style: TextStyle(
                            color: t['color'] as Color,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: t['pct'] as double,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(t['color'] as Color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildProductivityInsight() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights, color: Color(0xFF00FF88), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Insight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re most productive between 9-11 AM. Your distraction risk peaks at 10 PM. Consider setting a screen cutoff at 9:30 PM.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _insightChip('📈 +28% productivity', const Color(0xFF00FF88)),
              const SizedBox(width: 8),
              _insightChip('🌙 Late scroll risk', const Color(0xFFFF4D6D)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _insightChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
