import 'menu_item.dart';

/// Dummy menu data — replace with API data when backend is ready.
class DummyMenu {
  DummyMenu._();

  static final List<MenuItem> items = [
    // ── Meals ──────────────────────────────────────────────────────────────
    MenuItem(
      id: 'menu-001',
      name: 'Jollof Rice & Chicken',
      description:
          'Party-style jollof rice slow-cooked in rich tomato stew, served with a whole grilled chicken leg.',
      price: 'GH₵ 45.00',
      imageUrl:
          'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=600&q=80',
      category: 'Meals',
      isAvailable: true,
      isFeatured: true,
      prepTimeMinutes: 20,
      tags: ['Bestseller', 'Spicy'],
    ),
    MenuItem(
      id: 'menu-002',
      name: 'Waakye Special',
      description:
          'Rice and beans cooked with sorghum leaves, served with fried fish, boiled egg, shito and spaghetti.',
      price: 'GH₵ 35.00',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
      category: 'Meals',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 15,
      tags: ['Bestseller'],
    ),
    MenuItem(
      id: 'menu-003',
      name: 'Banku & Grilled Tilapia',
      description:
          'Fermented corn and cassava dough served with freshly grilled whole tilapia and hot pepper sauce.',
      price: 'GH₵ 65.00',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80',
      category: 'Meals',
      isAvailable: true,
      isFeatured: true,
      prepTimeMinutes: 25,
      tags: ['Spicy'],
    ),
    MenuItem(
      id: 'menu-004',
      name: 'Fried Rice & Chicken',
      description:
          'Seasoned fried rice with mixed vegetables and tender grilled chicken thighs on the side.',
      price: 'GH₵ 40.00',
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600&q=80',
      category: 'Meals',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 20,
      tags: [],
    ),
    MenuItem(
      id: 'menu-005',
      name: 'Fufu & Light Soup',
      description:
          'Pounded cassava and plantain served with freshly prepared light soup and goat meat.',
      price: 'GH₵ 55.00',
      imageUrl:
          'https://images.unsplash.com/photo-1547592180-85f173990554?w=600&q=80',
      category: 'Meals',
      isAvailable: false,
      isFeatured: false,
      prepTimeMinutes: 30,
      tags: ['Spicy'],
      isOutOfStock: false,
    ),

    // ── Sides ───────────────────────────────────────────────────────────────
    MenuItem(
      id: 'menu-006',
      name: 'Kelewele',
      description:
          'Spiced and fried ripe plantain cubes seasoned with ginger, pepper and spices.',
      price: 'GH₵ 15.00',
      imageUrl:
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&q=80',
      category: 'Sides',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 10,
      tags: ['Vegan', 'Spicy'],
    ),
    MenuItem(
      id: 'menu-007',
      name: 'Garden Egg Stew',
      description:
          'Slow-cooked garden eggs in a rich tomato and onion stew with smoked fish.',
      price: 'GH₵ 18.00',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80',
      category: 'Sides',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 15,
      tags: ['Vegan'],
    ),
    MenuItem(
      id: 'menu-008',
      name: 'Fried Plantain',
      description:
          'Golden fried sweet plantain slices. Simple, sweet and perfectly caramelised.',
      price: 'GH₵ 10.00',
      imageUrl:
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&q=80',
      category: 'Sides',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 8,
      tags: ['Vegan', 'Gluten-Free'],
    ),

    // ── Drinks ──────────────────────────────────────────────────────────────
    MenuItem(
      id: 'menu-009',
      name: 'Fresh Zobo Drink',
      description:
          'Chilled hibiscus flower drink infused with ginger, cloves and pineapple. Served cold.',
      price: 'GH₵ 12.00',
      imageUrl:
          'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=600&q=80',
      category: 'Drinks',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 5,
      tags: ['Vegan', 'New'],
    ),
    MenuItem(
      id: 'menu-010',
      name: 'Mango Smoothie',
      description:
          'Fresh Ghanaian mangoes blended with yoghurt and a touch of honey. No added sugar.',
      price: 'GH₵ 20.00',
      imageUrl:
          'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=600&q=80',
      category: 'Drinks',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 5,
      tags: ['Vegan', 'Gluten-Free'],
    ),

    // ── Snacks ──────────────────────────────────────────────────────────────
    MenuItem(
      id: 'menu-011',
      name: 'Beef Samosa (4 pcs)',
      description:
          'Crispy pastry pockets filled with spiced minced beef and vegetables. Served with chilli dip.',
      price: 'GH₵ 22.00',
      imageUrl:
          'https://images.unsplash.com/photo-1562967914-608f82629710?w=600&q=80',
      category: 'Snacks',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 12,
      tags: ['Spicy', 'Bestseller'],
    ),
    MenuItem(
      id: 'menu-012',
      name: 'Chin Chin',
      description:
          'Crunchy fried dough snack lightly sweetened with coconut flavour. Packed fresh daily.',
      price: 'GH₵ 8.00',
      imageUrl:
          'https://images.unsplash.com/photo-1548940740-204726a19be3?w=600&q=80',
      category: 'Snacks',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 5,
      tags: ['Vegetarian'],
    ),

    // ── Desserts ────────────────────────────────────────────────────────────
    MenuItem(
      id: 'menu-013',
      name: 'Puff Puff',
      description:
          'Light and fluffy fried dough balls dusted with icing sugar. A West African classic.',
      price: 'GH₵ 10.00',
      imageUrl:
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&q=80',
      category: 'Desserts',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 10,
      tags: ['Vegetarian', 'New'],
    ),

    // ── Breakfast ───────────────────────────────────────────────────────────
    MenuItem(
      id: 'menu-014',
      name: 'Hausa Koko & Koose',
      description:
          'Spiced millet porridge served with crispy bean cakes (koose). A traditional Ghanaian breakfast.',
      price: 'GH₵ 18.00',
      imageUrl:
          'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=600&q=80',
      category: 'Breakfast',
      isAvailable: true,
      isFeatured: false,
      prepTimeMinutes: 10,
      tags: ['Vegetarian', 'Seasonal'],
    ),

    // ── Specials ────────────────────────────────────────────────────────────
    MenuItem(
      id: 'menu-015',
      name: "Chef's Sunday Special",
      description:
          'Full Ghanaian platter — jollof, banku, grilled chicken, tilapia, kelewele and sobolo. Limited daily.',
      price: 'GH₵ 95.00',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
      category: 'Specials',
      isAvailable: true,
      isFeatured: true,
      prepTimeMinutes: 30,
      tags: ['Bestseller', 'Seasonal', 'Spicy'],
    ),
  ];
}
