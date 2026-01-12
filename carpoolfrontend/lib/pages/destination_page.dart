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

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final list = await api.getDestinations();
      setState(() {
        destinations = list;
      });
    } catch (e) {
      setState(() => error = 'Failed to load destinations: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destination'),
        actions: [
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
            : destinations.isEmpty
            ? const Text('No destinations yet.')
            : ListView.separated(
                itemCount: destinations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = destinations[index];
                  return ListTile(
                    title: Text(d.name),
                    subtitle: Text(d.addressText),
                  );
                },
              ),
      ),
    );
  }
}
