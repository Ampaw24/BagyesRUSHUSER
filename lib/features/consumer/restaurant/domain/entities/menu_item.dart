/// Menu item domain entity.
library;

class CustomizationOption {
  final String id;
  final String name;
  final double additionalPrice;

  const CustomizationOption({
    required this.id,
    required this.name,
    required this.additionalPrice,
  });
}

class MenuItemCustomization {
  final String id;
  final String name;
  final List<CustomizationOption> options;
  final bool isRequired;
  final int maxSelections;

  const MenuItemCustomization({
    required this.id,
    required this.name,
    required this.options,
    this.isRequired = false,
    this.maxSelections = 1,
  });
}

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final bool isAvailable;
  final bool isPopular;
  final List<MenuItemCustomization> customizations;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.isPopular = false,
    this.customizations = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is MenuItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
