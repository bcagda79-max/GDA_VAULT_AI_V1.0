// lib/models/category_model.dart
import 'package:flutter/material.dart';

/// Represents a document category.
class CategoryModel {
  final String id;
  final String name;
  final String? parentId;
  final Color color;
  final IconData iconData;
  final int docCount;
  final String? yearRange;
  final bool hasSubCategories;
  final List<String>? subCategories;
  final String? shortLabel;
  final int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.color,
    required this.iconData,
    required this.docCount,
    this.yearRange,
    this.hasSubCategories = false,
    this.subCategories,
    this.shortLabel,
    required this.sortOrder,
  });
}
