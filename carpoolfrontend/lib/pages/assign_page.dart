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

  void _runAssignment() {
    final drivers = List<Driver>.from(LocalStore.instance.drivers);
    final passengers = List<Passenger>.from(LocalStore.instance.passengers);

    if (drivers.isEmpty || passengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need drivers and passengers first')),
      );
      return;
    }

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

    setState(() {
      _result = result;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Assigned!')));
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _result.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _runAssignment,
              child: const Text('Run Assignment'),
            ),
            const SizedBox(height: 16),
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
