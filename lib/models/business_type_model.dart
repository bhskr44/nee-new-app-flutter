import 'package:flutter/material.dart';

class BusinessTypeModel {
  final int id;
  final String name;
  final String description;
  final String minInvestment;
  final String maxInvestment;
  final String expectedReturns;
  final String icon;
  final Color color;
  final List<String> steps;
  final List<String> documents;

  const BusinessTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.minInvestment,
    required this.maxInvestment,
    required this.expectedReturns,
    required this.icon,
    required this.color,
    required this.steps,
    required this.documents,
  });

  factory BusinessTypeModel.fromJson(Map<String, dynamic> json) {
    return BusinessTypeModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      minInvestment: json['min_investment'] ?? '',
      maxInvestment: json['max_investment'] ?? '',
      expectedReturns: json['expected_returns'] ?? '',
      icon: json['icon'] ?? 'construction',
      color: _parseColor(json['color'] ?? '#c62828'),
      steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
      documents: (json['documents'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  IconData get iconData => switch (icon) {
        'inventory' => Icons.inventory_2,
        'people' => Icons.people_alt,
        'design' => Icons.design_services,
        _ => Icons.construction,
      };

  static Color _parseColor(String value) {
    final hex = value.replaceAll('#', '');
    final normalized = hex.length == 6 ? 'ff$hex' : hex;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xffc62828);
  }
}
