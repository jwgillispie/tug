// lib/models/value_model.dart
import 'package:equatable/equatable.dart';

class ValueModel extends Equatable {
  final String? id;
  final String name;
  final int importance;
  final String description;
  final String color;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ValueModel({
    this.id,
    required this.name,
    required this.importance,
    this.description = '',
    required this.color,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  ValueModel copyWith({
    String? id,
    String? name,
    int? importance,
    String? description,
    String? color,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ValueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      importance: importance ?? this.importance,
      description: description ?? this.description,
      color: color ?? this.color,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'importance': importance,
      'description': description,
      'color': color,
      'active': active,
    };
  }

  factory ValueModel.fromJson(Map<String, dynamic> json) {
    return ValueModel(
      id: json['id'],
      name: json['name'],
      importance: json['importance'],
      description: json['description'] ?? '',
      color: json['color'],
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    name, 
    importance, 
    description, 
    color, 
    active, 
    createdAt, 
    updatedAt
  ];
}