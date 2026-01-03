import 'package:flutter/material.dart';

class AssignPage extends StatelessWidget {
  const AssignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assigned! (fake result)')),
            );
          },
          child: const Text('Run Assignment'),
        ),
      ),
    );
  }
}
