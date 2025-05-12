import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Health health = Health();
  HealthConnectSdkStatus? _hcStatus;
  bool _authorized = false;
  List<HealthDataPoint> _data = [];

  @override
  void initState() {
    super.initState();
    health.configure();                          // konfigurasi plugin
    _checkHealthConnectStatus();
  }

  Future<void> _checkHealthConnectStatus() async {
    final status = await health.getHealthConnectSdkStatus();
    setState(() => _hcStatus = status);
  }

  Future<void> _authorize() async {
    // minta permission runtime untuk steps/location
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // tipe data yang ingin diakses
    final types = [HealthDataType.STEPS];
    final perms = [HealthDataAccess.READ_WRITE];

    final granted = await health.requestAuthorization(types, permissions: perms);
    setState(() => _authorized = granted ?? false);
  }

  Future<void> _fetchSteps() async {
    if (!_authorized) return;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    // ambil total steps hari ini
    final total = await health.getTotalStepsInInterval(midnight, now);
    // atau ambil detail data point
    final pts = await health.getHealthDataFromTypes(
      types: [HealthDataType.STEPS],
      startTime: midnight,
      endTime: now,
    );
    setState(() {
      _data = health.removeDuplicates(pts);
    });
    debugPrint('Total steps: $total, points: ${_data.length}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Health Connect Demo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Health Connect Status: ${_hcStatus?.name}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _authorize,
                child: const Text('Authorize'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchSteps,
                child: const Text('Fetch Today\'s Steps'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: _data.map((p) => Text(
                    '${p.dateFrom} → ${p.value} ${p.unit}'
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
