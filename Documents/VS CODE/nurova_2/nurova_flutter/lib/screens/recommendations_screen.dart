import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<ContentModel> _items = [];
  bool _loading = false;
  String _selectedCategory = 'DSA';
  String _selectedRisk = 'high';

  final List<String> _categories = [
    'DSA', 'System Design', 'ML/AI', 'Web Dev', 'Productivity', 'Mindfulness',
  ];

  // Fallback curated content when API is unavailable
  final List<ContentModel> _fallbackContent = [
    ContentModel(
      title: '5 LeetCode Patterns You Must Know',
      url: 'https://youtube.com',
      thumbnail: 'https://picsum.photos/320/180?random=1',
      score: 0.94,
      channel: 'NeetCode',
      duration: '11 min',
    ),
    ContentModel(
      title: 'System Design Interview — Step by Step',
      url: 'https://youtube.com',
      thumbnail: 'https://picsum.photos/320/180?random=2',
      score: 0.91,
      channel: 'Gaurav Sen',
      duration: '14 min',
    ),
    ContentModel(
      title: 'Build a REST API with FastAPI in 10 min',
      url: 'https://youtube.com',
      thumbnail: 'https://picsum.photos/320/180?random=3',
      score: 0.88,
      channel: 'Tech With Tim',
      duration: '10 min',
    ),
    ContentModel(
      title: 'Focus Music — Deep Work 🎵',
      url: 'https://youtube.com',
      thumbnail: 'https://picsum.photos/320/180?random=4',
      score: 0.85,
      channel: 'Lofi Girl',
      duration: '1 hr',
    ),
    ContentModel(
      title: 'Pomodoro Technique — Actually Explained',
      url: 'https://youtube.com',
      thumbnail: 'https://picsum.photos/320/180?random=5',
      score: 0.82,
      channel: 'Thomas Frank',
      duration: '8 min',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getRecommendations(
        query: _selectedCategory,
        riskLevel: _selectedRisk,
        cluster: 'ProcrastinationBinger',
      );
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _items = _fallbackContent;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Learn Something Real'),
            pinned: false,
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCategoryPicker(),
                const SizedBox(height: 12),
                _buildRiskFilter(),
                const SizedBox(height: 16),
                _buildScoreAlgorithmInfo(),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF)))
                else
                  ..._items.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildContentCard(e.value, e.key),
                      )),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = cat);
              _loadRecommendations();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF6C63FF).withOpacity(0.3),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF6C63FF),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiskFilter() {
    final levels = ['low', 'medium', 'high'];
    return Row(
      children: [
        Text(
          'Risk Mode: ',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        ...levels.map((level) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedRisk = level);
                  _loadRecommendations();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedRisk == level
                        ? _riskLevelColor(level).withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _riskLevelColor(level).withOpacity(0.4)),
                  ),
                  child: Text(
                    level.toUpperCase(),
                    style: TextStyle(
                      color: _riskLevelColor(level),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildScoreAlgorithmInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF6C63FF), size: 16),
              const SizedBox(width: 8),
              Text(
                'Content Scoring Formula',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'score = goal_relevance×0.6 + user_interest×0.3 + mood_match×0.1\nFilter: score>0.7 AND duration<15min',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(ContentModel item, int index) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  item.thumbnail,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFF1A1A2E),
                    child: const Icon(Icons.play_circle_outline,
                        color: Colors.white54, size: 48),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.duration,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${(item.score * 100).round()}% match',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.channel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(item.url)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text(
                      'Watch Now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
  }

  Color _riskLevelColor(String level) {
    switch (level) {
      case 'low': return const Color(0xFF00FF88);
      case 'medium': return const Color(0xFFFFAA00);
      case 'high': return const Color(0xFFFF4D6D);
      default: return Colors.white;
    }
  }
}
