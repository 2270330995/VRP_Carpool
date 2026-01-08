import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../service/local_store.dart';

class DestinationPage extends StatefulWidget {
  const DestinationPage({super.key});

  @override
  State<DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<DestinationPage> {
  void _openForm() {
    final current = LocalStore.instance.destination;

    final nameController = TextEditingController(text: current?.name ?? '');
    final addressController = TextEditingController(
      text: current?.addressText ?? '',
    );
    final latController = TextEditingController(
      text: current?.lat.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: current?.lng.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(current == null ? 'Set Destination' : 'Edit Destination'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: latController,
                  decoration: const InputDecoration(labelText: 'Lat'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: lngController,
                  decoration: const InputDecoration(labelText: 'Lng'),
                  keyboardType: TextInputType.number,
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
              onPressed: () {
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());

                if (lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lat/Lng must be numbers')),
                  );
                  return;
                }

                final dest = Destination(
                  id:
                      current?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  addressText: addressController.text.trim(),
                  lat: lat,
                  lng: lng,
                );

                LocalStore.instance.setDestination(dest);
                Navigator.pop(context);
                setState(() {});
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
    final dest = LocalStore.instance.destination;

    return Scaffold(
      appBar: AppBar(title: const Text('Destination')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: dest == null
            ? const Text('No destination set yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${dest.name}'),
                  const SizedBox(height: 6),
                  Text('Address: ${dest.addressText}'),
                  const SizedBox(height: 6),
                  Text('Lat/Lng: ${dest.lat}, ${dest.lng}'),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
