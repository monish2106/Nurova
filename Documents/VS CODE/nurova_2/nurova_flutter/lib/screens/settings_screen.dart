import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiController = TextEditingController(text: 'http://localhost:5000');
  final _goalController = TextEditingController(text: 'Land a SWE internship');
  int _moodRating = 5;
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  int _screenTimeLimitHours = 6;
  String _savedMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiController.text =
          prefs.getString('api_base_url') ?? 'http://localhost:5000';
      _goalController.text = prefs.getString('user_goal') ?? 'Land a SWE internship';
      _moodRating = prefs.getInt('mood_score') ?? 5;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _screenTimeLimitHours = prefs.getInt('screen_time_limit') ?? 6;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _apiController.text);
    await prefs.setString('user_goal', _goalController.text);
    await prefs.setInt('mood_score', _moodRating);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setInt('screen_time_limit', _screenTimeLimitHours);
    await ApiService.saveBaseUrl(_apiController.text);
    setState(() => _savedMessage = '✅ Settings saved!');
    Future.delayed(const Duration(seconds: 2),
        () => setState(() => _savedMessage = ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Settings'),
            pinned: false,
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMoodLogger(),
                const SizedBox(height: 16),
                _buildGoalInput(),
                const SizedBox(height: 16),
                _buildApiConfig(),
                const SizedBox(height: 16),
                _buildNotificationSettings(),
                const SizedBox(height: 16),
                _buildScreenTimeLimit(),
                const SizedBox(height: 16),
                _buildSaveButton(),
                const SizedBox(height: 16),
                _buildAboutCard(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodLogger() {
    final emojis = ['😫', '😞', '😐', '🙂', '😄', '🤩', '🚀', '⚡', '🔥', '💯'];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling?',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'This helps calibrate your risk prediction',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = _moodRating == i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _moodRating = i + 1),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6C63FF).withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(emojis[i], style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mood: $_moodRating/10',
            style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildGoalInput() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Primary Goal',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Land a SWE internship',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: const Icon(Icons.flag_outlined, color: Color(0xFF6C63FF)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C63FF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildApiConfig() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.api, color: Color(0xFF00D4FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Backend API URL',
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Point to your Flask server (localhost or Render)',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'https://nurova-api.onrender.com',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00D4FF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNotificationSettings() {
    return GlassCard(
      child: Column(
        children: [
          _switchRow(
            'Risk Alerts',
            'Notify when risk exceeds 75%',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
            Icons.notification_important_outlined,
            const Color(0xFFFF4D6D),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _switchRow(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6C63FF),
        ),
      ],
    );
  }

  Widget _buildScreenTimeLimit() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Screen Time Limit',
                style: TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '$_screenTimeLimitHours hours',
                style: const TextStyle(
                    color: Color(0xFF6C63FF), fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _screenTimeLimitHours.toDouble(),
            min: 2,
            max: 12,
            divisions: 10,
            label: '$_screenTimeLimitHours hrs',
            activeColor: const Color(0xFF6C63FF),
            inactiveColor: const Color(0xFF6C63FF).withOpacity(0.2),
            onChanged: (v) => setState(() => _screenTimeLimitHours = v.round()),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSaveButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _savePrefs,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Save Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (_savedMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_savedMessage,
              style: const TextStyle(
                  color: Color(0xFF00FF88), fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  Widget _buildAboutCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nurova 2.0',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'AI-powered distraction detection • v2.0.0\nBuilt for the 7-Day Hackathon 🚀\nML: LogReg + RandomForest + KMeans',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _techChip('Flutter'),
              _techChip('Flask'),
              _techChip('Scikit-learn'),
              _techChip('SQLite'),
              _techChip('YouTube API'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _techChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
