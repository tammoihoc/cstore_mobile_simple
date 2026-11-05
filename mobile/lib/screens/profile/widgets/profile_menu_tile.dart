// Một dòng menu hồ sơ; nhận callback để màn hình quyết định nơi điều hướng.

import 'package:flutter/material.dart';
import 'package:cstore_mobile/screens/profile/widgets/profile_colors.dart';

Widget profileMenuTile(
        IconData icon, String title, String subtitle, VoidCallback? action) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          leading: CircleAvatar(
            backgroundColor: profileSage,
            child: Icon(icon, color: profileForest),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: profileMuted,
                fontSize: 12,
              ),
            ),
          ),
          trailing: action == null
              ? null
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: profileMuted,
                ),
          onTap: action,
        ),
      ),
    );
