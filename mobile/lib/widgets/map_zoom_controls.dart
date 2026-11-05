import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls(
      {super.key, required this.controller, this.onFit, this.ready = true});
  final MapController controller;
  final VoidCallback? onFit;
  final bool ready;

  void zoom(double delta) {
    if (!ready) return;
    final camera = controller.camera;
    controller.move(
        camera.center, (camera.zoom + delta).clamp(3, 19).toDouble());
  }

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Phóng to',
              onPressed: ready ? () => zoom(1) : null,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 30, child: Divider(height: 1)),
            IconButton(
              tooltip: 'Thu nhỏ',
              onPressed: ready ? () => zoom(-1) : null,
              icon: const Icon(Icons.remove),
            ),
            if (onFit != null) ...[
              const SizedBox(width: 30, child: Divider(height: 1)),
              IconButton(
                tooltip: 'Xem toàn bộ tuyến',
                onPressed: ready ? onFit : null,
                icon: const Icon(Icons.fit_screen_rounded),
              )
            ]
          ],
        ),
      );
}
