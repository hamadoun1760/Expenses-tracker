import 'package:flutter/material.dart';

class CustomDebtType {
  final int? id;
  final String name;
  final String iconName;
  final int colorValue;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomDebtType({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Getter to convert colorValue to Color object
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory CustomDebtType.fromMap(Map<String, dynamic> map) {
    return CustomDebtType(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      iconName: map['icon_name'] ?? 'account_balance',
      colorValue: map['color_value']?.toInt() ?? 0xFF1976D2,
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  CustomDebtType copyWith({
    int? id,
    String? name,
    String? iconName,
    int? colorValue,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomDebtType(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomDebtType{id: $id, name: $name, iconName: $iconName, colorValue: $colorValue, isDefault: $isDefault}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomDebtType &&
        other.id == id &&
        other.name == name &&
        other.iconName == iconName &&
        other.colorValue == colorValue &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        iconName.hashCode ^
        colorValue.hashCode ^
        isDefault.hashCode;
  }
}