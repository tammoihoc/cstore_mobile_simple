import 'dart:async';
import 'package:flutter/material.dart';

const orange = Color(0xFFED6A2C);
Widget heading(String title, [String? subtitle]) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(color: Colors.black54))
        ],
      ),
    );
Widget empty(String text) => Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    );
Future<void> attempt(
    BuildContext context, FutureOr<void> Function() action) async {
  try {
    await action();
  } on StateError catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không kết nối được máy chủ. Vui lòng thử lại.'),
      ));
    }
  }
}

Future<String?> ask(BuildContext context, String title,
    {String initial = ''}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
            title: Text(title),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, controller.text),
                child: const Text('Xác nhận'),
              )
            ],
          ));
  // Dispose after the dialog route has finished its exit animation.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  return result;
}
