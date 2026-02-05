class CustomCategory {
  final int? id;
  final String name;
  final String type; // 'expense' or 'income'
  final String iconName;
  final int colorValue;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomCategory({
    this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorValue,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon_name': iconName,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      type: map['type'] ?? 'expense',
      iconName: map['icon_name'] ?? 'category',
      colorValue: map['color_value']?.toInt() ?? 0xFF2196F3,
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  CustomCategory copyWith({
    int? id,
    String? name,
    String? type,
    String? iconName,
    int? colorValue,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomCategory{id: $id, name: $name, type: $type, iconName: $iconName, colorValue: $colorValue, isDefault: $isDefault}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomCategory &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.iconName == iconName &&
        other.colorValue == colorValue &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        type.hashCode ^
        iconName.hashCode ^
        colorValue.hashCode ^
        isDefault.hashCode;
  }
}