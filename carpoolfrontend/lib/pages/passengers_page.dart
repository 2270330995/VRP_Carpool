import 'package:flutter/material.dart';
import '../models/passenger.dart';
import '../service/api_service.dart';

class PassengersPage extends StatefulWidget {
  const PassengersPage({super.key});

  @override
  State<PassengersPage> createState() => _PassengersPageState();
}

class _PassengersPageState extends State<PassengersPage> {
  final ApiService api = ApiService(baseUrl: 'http://localhost:8080');

  bool _loading = true;
  String? _error;
  List<Passenger> _passengers = [];

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await api.getPassengers();
      setState(() {
        _passengers = list;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load passengers: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openAddDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Passenger'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final address = addrCtrl.text.trim();

                if (name.isEmpty || address.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name / Address required')),
                  );
                  return;
                }

                final passenger = Passenger(
                  id: '',
                  name: name,
                  addressText: address,
                );

                try {
                  await api.addPassenger(passenger);

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('added successfully')),
                  );

                  await _loadPassengers();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Add failed: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passengers'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPassengers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadPassengers,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : _passengers.isEmpty
            ? const Text('No passengers in backend yet.')
            : ListView.separated(
                itemCount: _passengers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _passengers[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.addressText),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
