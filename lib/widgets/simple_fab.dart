import 'package:flutter/material.dart';

/// Simple fallback FAB if the modern one has issues
class SimpleFAB extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onScanReceipt;

  const SimpleFAB({
    super.key,
    required this.onAddExpense,
    required this.onScanReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showActions(context),
      child: const Icon(Icons.add),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Expense'),
              onTap: () {
                Navigator.pop(context);
                onAddExpense();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scan Receipt'),
              onTap: () {
                Navigator.pop(context);
                onScanReceipt();
              },
            ),
          ],
        ),
      ),
    );
  }
}