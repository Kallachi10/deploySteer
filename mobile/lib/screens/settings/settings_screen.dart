import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:steermate/providers/auth_provider.dart';
import 'package:steermate/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _hardBrakeThreshold = 4.0;
  double _harshAccelThreshold = 4.0;
  double _curveThreshold = 2.5;
  double _overspeedMargin = 5.0;
  bool _hapticsEnabled = true;
  bool _audioEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _hardBrakeThreshold = await SettingsService.getHardBrakeThreshold();
    _harshAccelThreshold = await SettingsService.getHarshAccelThreshold();
    _curveThreshold = await SettingsService.getCurveThreshold();
    _overspeedMargin = await SettingsService.getOverspeedMargin();
    _hapticsEnabled = await SettingsService.getHapticsEnabled();
    _audioEnabled = await SettingsService.getAudioEnabled();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: Text(authProvider.email ?? 'Not logged in'),
            onTap: () {
              // Navigate to profile screen
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Alert Thresholds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildThresholdSlider(
            'Hard Brake Threshold',
            'Deceleration > this value triggers alert (m/s²)',
            _hardBrakeThreshold,
            2.0,
            8.0,
            (value) => setState(() => _hardBrakeThreshold = value),
            (value) => SettingsService.setHardBrakeThreshold(value),
          ),
          _buildThresholdSlider(
            'Harsh Acceleration Threshold',
            'Acceleration > this value triggers alert (m/s²)',
            _harshAccelThreshold,
            2.0,
            8.0,
            (value) => setState(() => _harshAccelThreshold = value),
            (value) => SettingsService.setHarshAccelThreshold(value),
          ),
          _buildThresholdSlider(
            'Unsafe Curve Threshold',
            'Lateral acceleration > this value triggers alert (m/s²)',
            _curveThreshold,
            1.5,
            4.0,
            (value) => setState(() => _curveThreshold = value),
            (value) => SettingsService.setCurveThreshold(value),
          ),
          _buildThresholdSlider(
            'Overspeed Margin',
            'Speed above limit + this margin triggers alert (km/h)',
            _overspeedMargin,
            0.0,
            20.0,
            (value) => setState(() => _overspeedMargin = value),
            (value) => SettingsService.setOverspeedMargin(value),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Alert Settings'),
            subtitle: Text('Configure alert sensitivity'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on alerts'),
            value: _hapticsEnabled,
            onChanged: (value) async {
              setState(() => _hapticsEnabled = value);
              await SettingsService.setHapticsEnabled(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Audio Alerts'),
            subtitle: const Text('Play sound on alerts'),
            value: _audioEnabled,
            onChanged: (value) async {
              setState(() => _audioEnabled = value);
              await SettingsService.setAudioEnabled(value);
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy'),
            subtitle: Text('Data usage and privacy settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('SteerMate v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SteerMate',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Advanced Driver Assistance System',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    ValueSetter<double> onSaved,
  ) {
    return Column(
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
          onChangeEnd: onSaved,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
