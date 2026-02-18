import 'package:flutter/material.dart';
import '../models/passenger.dart';
import '../models/place_selection.dart';
import '../models/plan_carpool_models.dart';
import '../service/api_service.dart';
import '../storage/demo_planner_store.dart';

class PassengersPage extends StatefulWidget {
  const PassengersPage({super.key});

  @override
  State<PassengersPage> createState() => _PassengersPageState();
}

class _PassengersPageState extends State<PassengersPage> {
  final ApiService api = ApiService(baseUrl: 'http://localhost:8080');
  final DemoPlannerStore _store = DemoPlannerStore.instance;

  bool _loading = true;
  String? _error;
  List<Passenger> _passengers = [];
  List<Passenger> _deletedPassengers = [];
  bool _showDeleted = false;

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
      final list = await api.getPassengers(includeInactive: true);
      final active = <Passenger>[];
      final inactive = <Passenger>[];
      for (final p in list) {
        if (p.active) {
          active.add(p);
        } else {
          inactive.add(p);
        }
      }
      setState(() {
        _passengers = active;
        _deletedPassengers = inactive;
      });
      await _store.ensureLoaded();
      final existing = _store.students;
      final mapped = active.map((p) {
        StudentInput? match;
        for (final s in existing) {
          if (s.id == p.id || s.name == p.name) {
            match = s;
            break;
          }
        }
        return StudentInput(
          id: p.id,
          name: p.name,
          home:
              match?.home ??
              PlaceSelection(
                placeId: '',
                description: p.addressText,
                location: LatLngPoint(lat: 0, lng: 0),
              ),
        );
      }).toList();
      _store.setStudents(mapped);
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

  Future<void> _confirmDelete(Passenger p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Passenger?'),
        content: Text('Delete "${p.name}"?\n\nYou can restore it later.'),
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
      await api.deletePassenger(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('deleted successfully')));
      await _loadPassengers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _restorePassenger(Passenger p) async {
    try {
      await api.restorePassenger(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('restored successfully')));
      await _loadPassengers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
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
            onPressed: () => setState(() => _showDeleted = !_showDeleted),
            icon: Icon(_showDeleted ? Icons.visibility_off : Icons.visibility),
            tooltip: _showDeleted ? 'Hide Deleted' : 'Show Deleted',
          ),
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
            : _passengers.isEmpty && _deletedPassengers.isEmpty
            ? const Text('No passengers in backend yet.')
            : ListView(
                children: [
                  if (_passengers.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Active',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._passengers.map(
                      (p) => ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.addressText),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(p),
                          tooltip: 'Delete',
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  if (_showDeleted && _deletedPassengers.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Deleted',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._deletedPassengers.map(
                      (p) => ListTile(
                        title: Text(p.name),
                        subtitle: Text(p.addressText),
                        trailing: IconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: () => _restorePassenger(p),
                          tooltip: 'Restore',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
