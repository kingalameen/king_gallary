import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:pattern_lock/pattern_lock.dart';

class LockSetupScreen extends StatefulWidget {
  const LockSetupScreen({super.key});

  @override
  State<LockSetupScreen> createState() => _LockSetupScreenState();
}

class _LockSetupScreenState extends State<LockSetupScreen> {
  String? _pin;
  String? _pattern;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lock Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Set PIN'),
            subtitle: const Text('Set a numeric PIN to unlock'),
            trailing: ElevatedButton(
              child: const Text('Set PIN'),
              onPressed: () async {
                // simple prompt
                final pin = await showDialog<String>(
                    context: context,
                    builder: (_) {
                      final ctrl = TextEditingController();
                      return AlertDialog(
                        title: const Text('Enter PIN'),
                        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save')),
                        ],
                      );
                    });
                if (pin != null && pin.isNotEmpty) {
                  await auth.setPin(pin);
                  setState(() => _pin = pin);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Set Pattern'),
          SizedBox(
            height: 300,
            child: PatternLock(
              dimension: 3,
              relativePadding: 0.7,
              showInput: true,
              onInputComplete: (points) async {
                final pattern = points.join('-');
                await auth.setPattern(pattern);
                setState(() => _pattern = pattern);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pattern saved')));
              },
            ),
          ),
        ],
      ),
    );
  }
}
