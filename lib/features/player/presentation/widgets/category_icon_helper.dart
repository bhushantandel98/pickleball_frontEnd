import 'package:flutter/material.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Returns a category-specific IconData for marketplace products.
IconData getCategoryIcon(ProductCategory category) {
  switch (category) {
    case ProductCategory.paddles:
      return Icons.sports_tennis;
    case ProductCategory.balls:
      return Icons.sports_baseball;
    case ProductCategory.shoes:
    case ProductCategory.footwear:
      return Icons.roller_skating;
    case ProductCategory.equipment:
      return Icons.fitness_center;
    case ProductCategory.apparel:
      return Icons.checkroom;
    case ProductCategory.accessories:
      return Icons.watch_outlined;
    case ProductCategory.bags:
      return Icons.backpack;
    case ProductCategory.all:
      return Icons.shopping_bag;
  }
}
