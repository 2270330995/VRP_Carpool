import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../service/api_service.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  final ApiService api = ApiService(baseUrl: 'http://localhost:8080');

  bool _loading = true;
  String? _error;
  List<Driver> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await api.getDrivers();
      setState(() => _drivers = list);
    } catch (e) {
      setState(() => _error = 'Failed to load drivers: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(Driver d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Driver?'),
        content: Text('Delete "${d.name}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await api.deleteDriver(d.id);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('deleted successfully')));

      await _loadDrivers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _openAddDialog() {
    final nameCtrl = TextEditingController();
    final seatsCtrl = TextEditingController(text: '1');
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Driver'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: seatsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seats'),
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
                final seats = int.tryParse(seatsCtrl.text.trim()) ?? 0;

                if (name.isEmpty || address.isEmpty || seats <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name / Seats / Address required'),
                    ),
                  );
                  return;
                }

                final driver = Driver(
                  id: '',
                  name: name,
                  seats: seats,
                  addressText: address,
                );

                try {
                  await api.addDriver(driver);

                  if (!mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('added successfully')),
                  );

                  await _loadDrivers();
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
        title: const Text('Drivers'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadDrivers,
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
                    onPressed: _loadDrivers,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : _drivers.isEmpty
            ? const Text('No drivers in backend yet.')
            : ListView.separated(
                itemCount: _drivers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = _drivers[index];
                  return ListTile(
                    title: Text(d.name),
                    subtitle: Text('${d.seats} seats • ${d.addressText}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(d),
                      tooltip: 'Delete',
                    ),
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
