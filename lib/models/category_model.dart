import 'package:flutter/material.dart';

/// Represents a document category (Supabase-compatible).
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final String storagePath;
  final Color color;
  final IconData iconData;
  final int docCount;
  final String yearRange;
  final bool hasSubCategories;
  final int? yearFrom;
  final int? yearTo;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    required this.storagePath,
    required this.color,
    required this.iconData,
    this.docCount = 0,
    required this.yearRange,
    this.hasSubCategories = false,
    this.yearFrom,
    this.yearTo,
    this.sortOrder = 0,
  });

  CategoryModel copyWith({bool? hasSubCategories, int? docCount}) {
    return CategoryModel(
      id: id,
      name: name,
      slug: slug,
      parentId: parentId,
      storagePath: storagePath,
      color: color,
      iconData: iconData,
      docCount: docCount ?? this.docCount,
      yearRange: yearRange,
      hasSubCategories: hasSubCategories ?? this.hasSubCategories,
      yearFrom: yearFrom,
      yearTo: yearTo,
      sortOrder: sortOrder,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    Color catColor = const Color(0xFF1A3A6B);
    
    // Unified Professional Brand Palette (Rich Executive Navy)
    // We use a single, premium navy for all categories as requested to keep it "Simple & Proper"
    catColor = const Color(0xFF1A3A6B); 
    
    // Fallback logic (Unlikely to be used now but kept for safety)
    final hex = map['color_hex'] as String?;
    if (hex != null && hex.isNotEmpty && hex != '#000000') {
      try {
        // If a specific color is explicitly provided in DB, we can still honor it
        // but by default, we use the unified brand navy above.
      } catch (_) {}
    }

    final yearFrom = _asInt(map['year_from']);
    final yearTo = _asInt(map['year_to']);

    final iconName = map['icon_name']?.toString() ?? 'folder';

    return CategoryModel(
      id: map['id'].toString(),
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      parentId: map['parent_id']?.toString(),
      storagePath: map['storage_path']?.toString() ?? '',
      color: catColor,
      iconData: iconFromName(iconName),
      docCount: _asInt(map['document_count']) ?? 0,
      yearRange: _buildYearRange(yearFrom, yearTo),
      yearFrom: yearFrom,
      yearTo: yearTo,
      sortOrder: _asInt(map['sort_order']) ?? 0,
    );
  }

  static String _buildYearRange(int? from, int? to) {
    if (from == null) return 'All years';
    if (to == null) return '$from – Ongoing';
    return '$from – $to';
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static IconData iconFromName(String name) {
    switch (name) {
      case 'gavel':
        return Icons.gavel_rounded;
      case 'handshake':
        return Icons.handshake_rounded;
      case 'location_city':
        return Icons.location_city_rounded;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings_rounded;
      case 'home_work':
        return Icons.home_work_rounded;
      case 'folder':
      default:
        return Icons.folder_rounded;
    }
  }
}
