import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:pattern_lock/pattern_lock.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtrl = TextEditingController();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBio();
  }

  Future<void> _checkBio() async {
    final has = await Provider.of<AuthService>(context, listen: false).hasBiometrics();
    setState(() => _biometricAvailable = has);
  }

  Future<void> _tryBiometric() async {
    final ok = await Provider.of<AuthService>(context, listen: false).authenticateWithBiometrics();
    if (ok) Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _tryPin() async {
    final stored = await Provider.of<AuthService>(context, listen: false).getPin();
    if (stored != null && stored == _pinCtrl.text) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unlock King Gallery', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 24),
                if (_biometricAvailable)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometrics'),
                    onPressed: _tryBiometric,
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PIN'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _tryPin, child: const Text('Unlock')),
                const SizedBox(height: 24),
                const Text('Or unlock with pattern'),
                SizedBox(
                  height: 220,
                  child: PatternLock(
                    dimension: 3,
                    relativePadding: 0.7,
                    showInput: true,
                    onInputComplete: (points) async {
                      final stored = await Provider.of<AuthService>(context, listen: false).getPattern();
                      final pattern = points.join('-');
                      if (stored != null && stored == pattern) {
                        Navigator.pushReplacementNamed(context, '/');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong pattern')));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/lock-setup'), child: const Text('Lock setup')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
