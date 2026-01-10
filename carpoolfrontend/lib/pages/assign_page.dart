import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/passenger.dart';
import '../service/local_store.dart';

class AssignPage extends StatefulWidget {
  const AssignPage({super.key});

  @override
  State<AssignPage> createState() => _AssignPageState();
}

class _AssignPageState extends State<AssignPage> {
  Map<Driver, List<Passenger>> _result = {};
  bool _assigning = false;

  void _runAssignment() async {
    if (_assigning) return;

    final drivers = List<Driver>.from(LocalStore.instance.drivers);
    final passengers = List<Passenger>.from(LocalStore.instance.passengers);

    if (drivers.isEmpty || passengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need drivers and passengers first')),
      );
      return;
    }

    setState(() {
      _assigning = true;
    });

    // ---- 本地最小分配逻辑（保留你原来的） ----
    final result = <Driver, List<Passenger>>{};
    for (final d in drivers) {
      result[d] = [];
    }

    int driverIndex = 0;
    for (final p in passengers) {
      int tries = 0;
      while (tries < drivers.length) {
        final d = drivers[driverIndex];
        if (result[d]!.length < d.seats) {
          result[d]!.add(p);
          break;
        }
        driverIndex = (driverIndex + 1) % drivers.length;
        tries++;
      }
    }
    // ------------------------------------------

    await Future.delayed(const Duration(milliseconds: 300)); // 模拟计算

    setState(() {
      _result = result;
      _assigning = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Assigned!')));
  }

  @override
  Widget build(BuildContext context) {
    final drivers = LocalStore.instance.drivers;
    final passengers = LocalStore.instance.passengers;
    final hasResult = _result.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -------- Current Selection 摘要 --------
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
                    Text('Drivers: ${drivers.length}'),
                    Text('Passengers: ${passengers.length}'),
                  ],
                ),
              ),
            ),

            // -------- Assign 按钮 --------
            ElevatedButton(
              onPressed: _assigning ? null : _runAssignment,
              child: _assigning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Assignment'),
            ),

            const SizedBox(height: 16),

            // -------- Result --------
            Expanded(
              child: !hasResult
                  ? const Center(child: Text('No assignment yet.'))
                  : ListView.separated(
                      itemCount: _result.keys.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final driver = _result.keys.elementAt(index);
                        final list = _result[driver]!;
                        return ListTile(
                          title: Text('${driver.name} (${driver.seats} seats)'),
                          subtitle: list.isEmpty
                              ? const Text('No passengers')
                              : Text(list.map((p) => p.name).join(', ')),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
