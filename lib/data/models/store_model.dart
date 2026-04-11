import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'store_model.g.dart';

@collection
class StoreModel {
  Id id = Isar.autoIncrement;

  late String uuid;
  late String name;
  late String category;     // grocery, pharmacy, electronics, etc.
  late double latitude;
  late double longitude;
  late String address;
  String? phoneNumber;
  String? openingHours;
  String? iconEmoji;
  late DateTime createdAt;
  late DateTime updatedAt;

  // color hex for map marker tint
  String markerColor = '#4ECDC4';

  @ignore
  bool get isOpen {
    // Simple check — can be extended with actual hours parsing
    final now = TimeOfDay.now();
    return now.hour >= 8 && now.hour < 22;
  }
}

/// Helper to instantiate StoreModel without named constructor (Isar requirement)
StoreModel createStore({
  required String uuid,
  required String name,
  required String category,
  required double latitude,
  required double longitude,
  required String address,
  String? phoneNumber,
  String? openingHours,
  String? iconEmoji,
  String markerColor = '#4ECDC4',
}) {
  final store = StoreModel()
    ..uuid = uuid
    ..name = name
    ..category = category
    ..latitude = latitude
    ..longitude = longitude
    ..address = address
    ..phoneNumber = phoneNumber
    ..openingHours = openingHours
    ..iconEmoji = iconEmoji
    ..markerColor = markerColor
    ..createdAt = DateTime.now()
    ..updatedAt = DateTime.now();
  return store;
}
