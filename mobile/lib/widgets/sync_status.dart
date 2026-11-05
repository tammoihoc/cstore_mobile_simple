import 'package:flutter/material.dart';
import '../services/app_state.dart';

class SyncStatus extends StatelessWidget {
  const SyncStatus({super.key, required this.state, required this.child});
  final AppState state;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (state.loading) const LinearProgressIndicator(minHeight: 2),
          if (state.error != null)
            MaterialBanner(
              content: Text(state.error!),
              actions: [
                TextButton(
                    onPressed: state.reload, child: const Text('Thử lại'))
              ],
            ),
          Expanded(child: child)
        ],
      );
}
