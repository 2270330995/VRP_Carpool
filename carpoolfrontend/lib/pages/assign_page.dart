import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/destination.dart';
import '../service/api_service.dart';

class AssignPage extends StatefulWidget {
  const AssignPage({super.key});

  @override
  State<AssignPage> createState() => _AssignPageState();
}

class _AssignPageState extends State<AssignPage> {
  final ApiService api = ApiService(baseUrl: 'http://localhost:8080');
  final TextEditingController noteCtrl = TextEditingController();

  bool loadingDest = true;
  bool assigning = false;
  String? error;

  int _driversCount = 0;
  int _passengersCount = 0;

  List<Destination> destinations = [];
  Destination? selected;

  Map<String, dynamic>? latestRun;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final drivers = await api.getDrivers();
      final passengers = await api.getPassengers();
      setState(() {
        _driversCount = drivers.length;
        _passengersCount = passengers.length;
      });
    } catch (_) {
      // 忽略，避免影响主流程
    }
  }

  Future<void> _loadDestinations() async {
    setState(() {
      loadingDest = true;
      error = null;
    });

    try {
      final list = await api.getDestinations();
      setState(() {
        destinations = list;
        selected = list.isNotEmpty ? list.first : null;
      });
    } catch (e) {
      setState(() => error = 'Failed to load destinations: $e');
    } finally {
      setState(() => loadingDest = false);
    }
  }

  Future<void> _runAssign() async {
    if (assigning) return;

    if (_driversCount == 0 || _passengersCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need drivers and passengers first')),
      );
      return;
    }
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    setState(() {
      assigning = true;
      error = null;
    });

    try {
      await api.assign(
        destinationId: int.parse(selected!.id),
        note: noteCtrl.text,
      );

      final run = await api.getLatestRun();

      setState(() {
        latestRun = run;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assigned!')));
    } catch (e) {
      setState(() => error = 'Assign failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Assign failed: $e')));
    } finally {
      if (mounted) setState(() => assigning = false);
    }
  }

  Future<void> _navigate(int runId, int driverId) async {
    try {
      final url = await api.getNavigateUrl(runId: runId, driverId: driverId);
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open navigation URL')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigate failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = (latestRun?['plans'] as List?) ?? const [];
    final unassigned = (latestRun?['unassigned'] as List?) ?? const [];
    final runId = (latestRun?['runId'] as num?)?.toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign'),
        actions: [
          IconButton(
            onPressed: loadingDest ? null : _loadDestinations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Current Selection ----
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Selection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Drivers: $_driversCount'),
                    Text('Passengers: $_passengersCount'),
                  ],
                ),
              ),
            ),

            // ---- Destination dropdown + note ----
            if (loadingDest)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null && destinations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadDestinations,
                      child: const Text('Retry loading destinations'),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Destination>(
                    value: selected,
                    items: destinations
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text('${d.name} — ${d.addressText}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // ---- Assign button ----
            ElevatedButton(
              onPressed: assigning ? null : _runAssign,
              child: assigning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Assignment'),
            ),

            if (error != null && destinations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 16),

            // ---- Results ----
            Expanded(
              child: latestRun == null
                  ? const Center(child: Text('No assignment yet.'))
                  : ListView(
                      children: [
                        Text(
                          'Run #${latestRun!['runId']}  •  ${latestRun!['createdAt']}',
                        ),
                        const SizedBox(height: 12),

                        ...plans.map((p) {
                          final plan = p as Map;
                          final driverId =
                              (plan['driverId'] as num?)?.toInt() ?? -1;
                          final driverName = (plan['driverName'] ?? '')
                              .toString();
                          final seats = (plan['seats'] as num?)?.toInt() ?? 0;
                          final stops = (plan['stops'] as List?) ?? const [];

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$driverName ($seats seats)',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (runId != null && driverId != -1)
                                        OutlinedButton(
                                          onPressed: () =>
                                              _navigate(runId, driverId),
                                          child: const Text('Navigate'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (stops.isEmpty)
                                    const Text('No passengers')
                                  else
                                    ...stops.map((s) {
                                      final stop = s as Map;
                                      final order =
                                          (stop['order'] as num?)?.toInt() ?? 0;
                                      final pname =
                                          (stop['passengerName'] ?? '')
                                              .toString();
                                      final paddr =
                                          (stop['passengerAddress'] ?? '')
                                              .toString();
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          radius: 14,
                                          child: Text('$order'),
                                        ),
                                        title: Text(pname),
                                        subtitle: Text(paddr),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 12),
                        const Text(
                          'Unassigned',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (unassigned.isEmpty)
                          const Text('None')
                        else
                          ...unassigned.map((u) {
                            final uu = u as Map;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                (uu['passengerName'] ?? '').toString(),
                              ),
                              subtitle: Text(
                                (uu['passengerAddress'] ?? '').toString(),
                              ),
                            );
                          }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
