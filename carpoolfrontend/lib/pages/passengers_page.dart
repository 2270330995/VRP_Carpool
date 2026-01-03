import 'package:flutter/material.dart';

class PassengersPage extends StatelessWidget {
  const PassengersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passengers')),
      body: const Center(child: Text('Passengers page (coming soon)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add Passenger (TODO)')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
