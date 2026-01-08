import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../service/local_store.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  void _openForm({Driver? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final seatsController = TextEditingController(
      text: existing?.seats.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: existing?.addressText ?? '',
    );
    final latController = TextEditingController(
      text: existing?.lat.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: existing?.lng.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Driver' : 'Edit Driver'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: seatsController,
                  decoration: const InputDecoration(labelText: 'Seats'),
                  keyboardType: TextInputType.number,
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
                final seats = int.tryParse(seatsController.text.trim());
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());

                if (seats == null || lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seats/Lat/Lng must be numbers'),
                    ),
                  );
                  return;
                }

                final driver = Driver(
                  id:
                      existing?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  seats: seats,
                  addressText: addressController.text.trim(),
                  lat: lat,
                  lng: lng,
                );

                if (existing == null) {
                  LocalStore.instance.addDriver(driver);
                } else {
                  LocalStore.instance.updateDriver(driver);
                }

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

  void _deleteDriver(Driver driver) {
    LocalStore.instance.deleteDriver(driver.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final drivers = LocalStore.instance.drivers;

    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: drivers.isEmpty
            ? const Center(child: Text('No drivers yet.'))
            : ListView.separated(
                itemCount: drivers.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final d = drivers[index];
                  return ListTile(
                    title: Text('${d.name} (${d.seats} seats)'),
                    subtitle: Text(d.addressText),
                    onTap: () => _openForm(existing: d),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteDriver(d),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
