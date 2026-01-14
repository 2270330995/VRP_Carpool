import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../service/api_service.dart';

class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  final ApiService api = ApiService(baseUrl: 'http://localhost:8080');

  bool loading = true;
  String? error;
  List<Destination> destinations = [];
  List<Destination> deletedDestinations = [];
  bool showDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _confirmDelete(Destination d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Destination?'),
        content: Text('Delete "${d.name}"?\n\nYou can restore it later.'),
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
      await api.deleteDestination(d.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('deleted successfully')));
      await _loadDestinations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _restoreDestination(Destination d) async {
    try {
      await api.restoreDestination(d.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('restored successfully')));
      await _loadDestinations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _loadDestinations() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final list = await api.getDestinations(includeInactive: true);
      final active = <Destination>[];
      final inactive = <Destination>[];
      for (final d in list) {
        if (d.active) {
          active.add(d);
        } else {
          inactive.add(d);
        }
      }
      setState(() {
        destinations = active;
        deletedDestinations = inactive;
      });
    } catch (e) {
      setState(() => error = 'Failed to load destinations: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _openAddDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Destination'),
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

                final dest = Destination(
                  id: '',
                  name: name,
                  addressText: address,
                );

                try {
                  await api.addDestination(dest);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('added successfully')),
                  );
                  await _loadDestinations();
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
        title: const Text('Destination'),
        actions: [
          IconButton(
            onPressed: () => setState(() => showDeleted = !showDeleted),
            icon: Icon(showDeleted ? Icons.visibility_off : Icons.visibility),
            tooltip: showDeleted ? 'Hide Deleted' : 'Show Deleted',
          ),
          IconButton(
            onPressed: loading ? null : _loadDestinations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadDestinations,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : destinations.isEmpty && deletedDestinations.isEmpty
            ? const Text('No destinations yet.')
            : ListView(
                children: [
                  if (destinations.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Active',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...destinations.map(
                      (d) => ListTile(
                        title: Text(d.name),
                        subtitle: Text(d.addressText),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(d),
                          tooltip: 'Delete',
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  if (showDeleted && deletedDestinations.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Deleted',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...deletedDestinations.map(
                      (d) => ListTile(
                        title: Text(d.name),
                        subtitle: Text(d.addressText),
                        trailing: IconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: () => _restoreDestination(d),
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
