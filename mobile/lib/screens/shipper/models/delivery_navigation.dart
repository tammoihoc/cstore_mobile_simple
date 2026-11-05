// Đổi JSON thành bước chỉ dẫn, chặng đường và hành trình giao hàng.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RoadStep {
  const RoadStep(
      {required this.name,
      required this.type,
      required this.modifier,
      required this.distanceMeters});
  final String name, type, modifier;
  final double distanceMeters;
  factory RoadStep.fromJson(Map<String, dynamic> json) => RoadStep(
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        modifier: json['modifier'] as String? ?? '',
        distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      );

  String get instruction {
    final road = name.trim().isEmpty ? '' : ' vào $name';
    return switch (type) {
      'depart' => name.isEmpty ? 'Bắt đầu di chuyển' : 'Đi theo $name',
      'arrive' => 'Đến điểm nhận / giao hàng',
      'roundabout' || 'rotary' => 'Đi qua vòng xuyến$road',
      'exit roundabout' || 'exit rotary' => 'Ra khỏi vòng xuyến$road',
      'merge' => 'Nhập làn$road',
      'fork' =>
        modifier.contains('left') ? 'Giữ bên trái$road' : 'Giữ bên phải$road',
      _ => switch (modifier) {
          'left' => 'Rẽ trái$road',
          'right' => 'Rẽ phải$road',
          'slight left' => 'Chếch trái$road',
          'slight right' => 'Chếch phải$road',
          'sharp left' => 'Rẽ ngoặt trái$road',
          'sharp right' => 'Rẽ ngoặt phải$road',
          'uturn' => 'Quay đầu$road',
          _ => name.isEmpty ? 'Tiếp tục đi thẳng' : 'Tiếp tục theo $name'
        }
    };
  }

  IconData get icon => switch (modifier) {
        'left' || 'slight left' || 'sharp left' => Icons.turn_left_rounded,
        'right' || 'slight right' || 'sharp right' => Icons.turn_right_rounded,
        'uturn' => Icons.u_turn_left_rounded,
        _ => type == 'arrive' ? Icons.flag_rounded : Icons.straight_rounded
      };
}

class RoadLeg {
  const RoadLeg(
      {required this.distanceKm,
      required this.durationSeconds,
      required this.points,
      required this.steps});
  final double distanceKm, durationSeconds;
  final List<LatLng> points;
  final List<RoadStep> steps;
  factory RoadLeg.fromJson(Map<String, dynamic> json) => RoadLeg(
        distanceKm: (json['distanceKm'] as num).toDouble(),
        durationSeconds: (json['durationSeconds'] as num).toDouble(),
        points: [
          for (final raw in json['coordinates'] as List)
            LatLng((raw[1] as num).toDouble(), (raw[0] as num).toDouble())
        ],
        steps: [
          for (final raw in json['steps'] as List? ?? [])
            RoadStep.fromJson(raw as Map<String, dynamic>)
        ],
      );
  String get distanceLabel => distanceKm < 1
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(2)} km';
  String get durationLabel => durationSeconds < 60
      ? 'Dưới 1 phút'
      : '${(durationSeconds / 60).ceil()} phút';
}

class DeliveryNavigation {
  const DeliveryNavigation(
      {required this.stage,
      required this.simulated,
      required this.driver,
      required this.store,
      required this.customer,
      required this.pickup,
      required this.delivery,
      required this.active});
  final String stage;
  final bool simulated;
  final LatLng driver, store, customer;
  final RoadLeg? pickup;
  final RoadLeg delivery, active;
  factory DeliveryNavigation.fromJson(Map<String, dynamic> json) =>
      DeliveryNavigation(
        stage: json['stage'] as String,
        simulated: json['simulated'] == true,
        driver: LatLng(
          (json['shipperLatitude'] as num).toDouble(),
          (json['shipperLongitude'] as num).toDouble(),
        ),
        store: LatLng(
          (json['storeLatitude'] as num).toDouble(),
          (json['storeLongitude'] as num).toDouble(),
        ),
        customer: LatLng(
          (json['customerLatitude'] as num).toDouble(),
          (json['customerLongitude'] as num).toDouble(),
        ),
        pickup: json['pickupRoute'] == null
            ? null
            : RoadLeg.fromJson(json['pickupRoute'] as Map<String, dynamic>),
        delivery:
            RoadLeg.fromJson(json['deliveryRoute'] as Map<String, dynamic>),
        active: RoadLeg.fromJson(json['activeRoute'] as Map<String, dynamic>),
      );
  bool get toStore => stage == 'PICKUP';
  String get title => toStore
      ? 'Đến cửa hàng nhận hàng'
      : stage == 'COMPLETED'
          ? 'Đã hoàn tất giao hàng'
          : 'Giao hàng đến khách';
}
