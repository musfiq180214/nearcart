import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
@collection
class StoreModel {
  StoreModel();

  Id id = Isar.autoIncrement;

  late String uuid;
  late String userId; // ← NEW: owner's Firebase UID
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

  Map<String, dynamic> toJson() =>
      {
        'uuid': uuid,
        'userId': userId,
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

  factory StoreModel.fromJson(Map<String, dynamic> json) =>
      StoreModel()
        ..uuid = json['uuid'] ?? ''
        ..userId = json['userId'] ?? ''
        ..name = json['name'] ?? ''
        ..category = json['category'] ?? ''
        ..latitude = (json['latitude'] as num?)?.toDouble() ?? 0.0 // Safe cast
        ..longitude = (json['longitude'] as num?)?.toDouble() ??
            0.0 // Safe cast
        ..address = json['address'] ?? ''
        ..phoneNumber = json['phoneNumber']
        ..openingHours = json['openingHours']
        ..iconEmoji = json['iconEmoji']
        ..markerColor = json['markerColor'] ?? '#4ECDC4'
        ..createdAt = _parseDate(json['createdAt']) // Use helper
        ..updatedAt = _parseDate(json['updatedAt']); // Use helper

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}