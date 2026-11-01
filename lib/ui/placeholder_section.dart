import 'package:flutter/material.dart';

/// Card for a feature that is planned but not built yet.
class PlaceholderTile extends StatelessWidget {
  const PlaceholderTile({super.key, required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Chip(label: Text('Soon')),
      ),
    );
  }
}
