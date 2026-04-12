// import 'package:flutter/material.dart';
// import 'package:isar/isar.dart';
//
// part 'store_model.g.dart';
//
// @collection
// class StoreModel {
//   Id id = Isar.autoIncrement;
//
//   late String uuid;
//   late String name;
//   late String category;     // grocery, pharmacy, electronics, etc.
//   late double latitude;
//   late double longitude;
//   late String address;
//   String? phoneNumber;
//   String? openingHours;
//   String? iconEmoji;
//   late DateTime createdAt;
//   late DateTime updatedAt;
//
//   // color hex for map marker tint
//   String markerColor = '#4ECDC4';
//
//   @ignore
//   bool get isOpen {
//     // Simple check — can be extended with actual hours parsing
//     final now = TimeOfDay.now();
//     return now.hour >= 8 && now.hour < 22;
//   }
// }
//
// /// Helper to instantiate StoreModel without named constructor (Isar requirement)
// StoreModel createStore({
//   required String uuid,
//   required String name,
//   required String category,
//   required double latitude,
//   required double longitude,
//   required String address,
//   String? phoneNumber,
//   String? openingHours,
//   String? iconEmoji,
//   String markerColor = '#4ECDC4',
// }) {
//   final store = StoreModel()
//     ..uuid = uuid
//     ..name = name
//     ..category = category
//     ..latitude = latitude
//     ..longitude = longitude
//     ..address = address
//     ..phoneNumber = phoneNumber
//     ..openingHours = openingHours
//     ..iconEmoji = iconEmoji
//     ..markerColor = markerColor
//     ..createdAt = DateTime.now()
//     ..updatedAt = DateTime.now();
//   return store;
// }


import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'store_model.g.dart';

@collection
class StoreModel {
  StoreModel(); // ✅ ADD THIS LINE

  Id id = Isar.autoIncrement;

  late String uuid;
  late String name;
  late String category;
  late double latitude;
  late double longitude;
  late String address;
  String? phoneNumber;
  String? openingHours;
  String? iconEmoji;
  late DateTime createdAt;
  late DateTime updatedAt;
  String markerColor = '#4ECDC4';

  @ignore
  bool get isOpen {
    final now = TimeOfDay.now();
    return now.hour >= 8 && now.hour < 22;
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'phoneNumber': phoneNumber,
      'openingHours': openingHours,
      'iconEmoji': iconEmoji,
      'markerColor': markerColor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final store = StoreModel()
      ..uuid = json['uuid']
      ..name = json['name']
      ..category = json['category']
      ..latitude = (json['latitude'] as num).toDouble()
      ..longitude = (json['longitude'] as num).toDouble()
      ..address = json['address']
      ..phoneNumber = json['phoneNumber']
      ..openingHours = json['openingHours']
      ..iconEmoji = json['iconEmoji']
      ..markerColor = json['markerColor'] ?? '#4ECDC4'
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt']);

    return store;
  }
}