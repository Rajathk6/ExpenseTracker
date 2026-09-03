import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/lock_service.dart';

/// Phase 0 placeholder lock screen. Phase 10 adds PIN pad + biometric + decoy PIN.
class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => ref.read(lockProvider.notifier).unlock(ok: true),
          child: const Text('Unlock (stub — Phase 10 adds PIN + biometric)'),
        ),
      ),
    );
  }
}
