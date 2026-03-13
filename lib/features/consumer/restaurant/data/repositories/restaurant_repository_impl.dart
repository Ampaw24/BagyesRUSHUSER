import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/repositories/i_restaurant_repository.dart';

/// Mock implementation — replace datasource calls with real Dio/API later.
/// All data is realistic for a Ghanaian food-delivery context.
class RestaurantRepositoryImpl implements IRestaurantRepository {
  // ─── Singleton mock data store ───────────────────────────────────────────

  static final List<Restaurant> _restaurants = [
    const Restaurant(
      id: 'r1',
      name: 'KFC Ghana',
      imageUrl:
          'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=600',
      cuisineType: 'Fast Food',
      categories: ['Chicken', 'Burgers', 'Sides', 'Drinks', 'Combos'],
      rating: 4.5,
      reviewCount: 1842,
      deliveryTimeMin: 20,
      deliveryTimeMax: 35,
      deliveryFee: 8.00,
      minOrder: 30.00,
      isOpen: true,
      isFeatured: true,
      address: 'Airport City, Accra',
      latitude: 5.6037,
      longitude: -0.1870,
      promoText: '20% off combos',
      discountPercent: 20,
    ),
    const Restaurant(
      id: 'r2',
      name: 'Papaye Fast Food',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      cuisineType: 'Ghanaian · Fast Food',
      categories: ['Rice Dishes', 'Chicken', 'Stews', 'Drinks'],
      rating: 4.3,
      reviewCount: 3210,
      deliveryTimeMin: 25,
      deliveryTimeMax: 40,
      deliveryFee: 7.00,
      minOrder: 25.00,
      isOpen: true,
      isFeatured: true,
      address: 'Osu, Accra',
      latitude: 5.5600,
      longitude: -0.1857,
      promoText: 'Free delivery above GHS 60',
    ),
    const Restaurant(
      id: 'r3',
      name: 'Chow Noodle Bar',
      imageUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
      cuisineType: 'Chinese · Asian',
      categories: ['Noodles', 'Fried Rice', 'Dim Sum', 'Soups', 'Drinks'],
      rating: 4.7,
      reviewCount: 987,
      deliveryTimeMin: 30,
      deliveryTimeMax: 45,
      deliveryFee: 10.00,
      minOrder: 40.00,
      isOpen: true,
      isFeatured: false,
      address: 'East Legon, Accra',
      latitude: 5.6345,
      longitude: -0.1571,
    ),
    const Restaurant(
      id: 'r4',
      name: 'Buka Joint',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600',
      cuisineType: 'Local · Ghanaian',
      categories: ['Soups', 'Stews', 'Fufu', 'Rice', 'Drinks'],
      rating: 4.6,
      reviewCount: 2415,
      deliveryTimeMin: 20,
      deliveryTimeMax: 35,
      deliveryFee: 5.00,
      minOrder: 20.00,
      isOpen: true,
      isFeatured: true,
      address: 'Dzorwulu, Accra',
      latitude: 5.5998,
      longitude: -0.2083,
      promoText: 'Local favourite 🇬🇭',
    ),
    const Restaurant(
      id: 'r5',
      name: 'Pizza Inn',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600',
      cuisineType: 'Pizza · Italian',
      categories: ['Pizzas', 'Pasta', 'Sides', 'Desserts', 'Drinks'],
      rating: 4.2,
      reviewCount: 654,
      deliveryTimeMin: 35,
      deliveryTimeMax: 50,
      deliveryFee: 12.00,
      minOrder: 50.00,
      isOpen: true,
      isFeatured: false,
      address: 'Accra Mall, Accra',
      latitude: 5.6297,
      longitude: -0.2022,
      promoText: 'Buy 1 Get 1 Tues',
      discountPercent: 50,
    ),
    const Restaurant(
      id: 'r6',
      name: 'Marwako Fast Food',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      cuisineType: 'Local · Lebanese',
      categories: ['Rice', 'Grills', 'Wraps', 'Salads', 'Drinks'],
      rating: 4.4,
      reviewCount: 1678,
      deliveryTimeMin: 25,
      deliveryTimeMax: 40,
      deliveryFee: 8.00,
      minOrder: 30.00,
      isOpen: false,
      isFeatured: false,
      address: 'Spintex Road, Accra',
      latitude: 5.6558,
      longitude: -0.1343,
    ),
    const Restaurant(
      id: 'r7',
      name: 'Shake & Burger Co.',
      imageUrl:
          'https://images.unsplash.com/photo-1550547660-d9450f859349?w=600',
      cuisineType: 'American · Burgers',
      categories: ['Burgers', 'Fries', 'Shakes', 'Hot Dogs', 'Drinks'],
      rating: 4.8,
      reviewCount: 423,
      deliveryTimeMin: 20,
      deliveryTimeMax: 30,
      deliveryFee: 9.00,
      minOrder: 35.00,
      isOpen: true,
      isFeatured: true,
      address: 'Cantonments, Accra',
      latitude: 5.5773,
      longitude: -0.1876,
      promoText: 'New in town!',
    ),
    const Restaurant(
      id: 'r8',
      name: 'The Healthy Bowl',
      imageUrl:
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600',
      cuisineType: 'Healthy · Salads',
      categories: ['Bowls', 'Salads', 'Smoothies', 'Wraps', 'Snacks'],
      rating: 4.6,
      reviewCount: 312,
      deliveryTimeMin: 25,
      deliveryTimeMax: 35,
      deliveryFee: 10.00,
      minOrder: 40.00,
      isOpen: true,
      isFeatured: false,
      address: 'Labone, Accra',
      latitude: 5.5691,
      longitude: -0.1688,
    ),
  ];

  static final Map<String, List<MenuItem>> _menusByRestaurant = {
    'r1': _kfcMenu,
    'r2': _papayeMenu,
    'r3': _chowMenu,
    'r4': _bukaMenu,
    'r5': _pizzaMenu,
    'r6': _marwakoMenu,
    'r7': _burgerMenu,
    'r8': _healthyMenu,
  };

  // ─── IRestaurantRepository ─────────────────────────────────────────────

  @override
  Future<List<Restaurant>> getRestaurants({String? category}) async {
    await _fakeDelay();
    if (category == null || category == 'All') return _restaurants;
    return _restaurants
        .where((r) => r.cuisineType.contains(category) ||
            r.categories.any((c) => c.toLowerCase() == category.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Restaurant>> getFeaturedRestaurants() async {
    await _fakeDelay();
    return _restaurants.where((r) => r.isFeatured).toList();
  }

  @override
  Future<List<Restaurant>> getNearbyRestaurants() async {
    await _fakeDelay();
    // Mock: return open restaurants in order of id
    return _restaurants.where((r) => r.isOpen).take(5).toList();
  }

  @override
  Future<Restaurant> getRestaurantById(String id) async {
    await _fakeDelay(ms: 300);
    return _restaurants.firstWhere((r) => r.id == id);
  }

  @override
  Future<Map<String, List<MenuItem>>> getMenu(String restaurantId) async {
    await _fakeDelay();
    final items = _menusByRestaurant[restaurantId] ?? [];
    final grouped = <String, List<MenuItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  @override
  Future<List<Restaurant>> search(String query) async {
    await _fakeDelay(ms: 300);
    final q = query.toLowerCase();
    return _restaurants.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.cuisineType.toLowerCase().contains(q) ||
          r.categories.any((c) => c.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _fakeDelay({int ms = 600}) =>
      Future.delayed(Duration(milliseconds: ms));

  // ─── KFC menu ────────────────────────────────────────────────────────────

  static const _kfcMenu = [
    MenuItem(
      id: 'r1_m1', restaurantId: 'r1',
      name: 'Zinger Burger',
      description: 'Spicy crispy chicken fillet with fresh lettuce & mayo',
      imageUrl: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400',
      price: 42.00, category: 'Burgers', isPopular: true,
    ),
    MenuItem(
      id: 'r1_m2', restaurantId: 'r1',
      name: '3-Piece Original',
      description: 'Three pieces of KFC\'s legendary Original Recipe chicken',
      imageUrl: 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400',
      price: 68.00, category: 'Chicken', isPopular: true,
    ),
    MenuItem(
      id: 'r1_m3', restaurantId: 'r1',
      name: 'Bucket for 4',
      description: '8 pieces of Original or Hot & Crispy chicken',
      imageUrl: 'https://images.unsplash.com/photo-1615361200141-f45040f367be?w=400',
      price: 195.00, category: 'Combos', isPopular: true,
    ),
    MenuItem(
      id: 'r1_m4', restaurantId: 'r1',
      name: 'Coleslaw (Large)',
      description: 'Creamy, freshly made coleslaw',
      imageUrl: 'https://images.unsplash.com/photo-1604909052743-94e838986d24?w=400',
      price: 18.00, category: 'Sides',
    ),
    MenuItem(
      id: 'r1_m5', restaurantId: 'r1',
      name: 'Pepsi (500ml)',
      description: 'Chilled Pepsi Cola',
      imageUrl: 'https://images.unsplash.com/photo-1601049676869-702ea24cfd58?w=400',
      price: 12.00, category: 'Drinks',
    ),
  ];

  // ─── Papaye menu ──────────────────────────────────────────────────────────

  static const _papayeMenu = [
    MenuItem(
      id: 'r2_m1', restaurantId: 'r2',
      name: 'Jollof Rice + Chicken',
      description: 'Smoky party jollof rice with grilled or fried chicken',
      imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
      price: 55.00, category: 'Rice Dishes', isPopular: true,
    ),
    MenuItem(
      id: 'r2_m2', restaurantId: 'r2',
      name: 'Fried Rice + Tilapia',
      description: 'Vegetable fried rice with whole fried tilapia',
      imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
      price: 65.00, category: 'Rice Dishes',
    ),
    MenuItem(
      id: 'r2_m3', restaurantId: 'r2',
      name: 'Waakye Special',
      description: 'Rice & beans with spaghetti, shito, egg, gari & fish',
      imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
      price: 50.00, category: 'Rice Dishes', isPopular: true,
    ),
    MenuItem(
      id: 'r2_m4', restaurantId: 'r2',
      name: 'Quarter Chicken',
      description: 'Flame-grilled seasoned chicken quarter',
      imageUrl: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c7?w=400',
      price: 38.00, category: 'Chicken',
    ),
    MenuItem(
      id: 'r2_m5', restaurantId: 'r2',
      name: 'Light Soup + Fufu',
      description: 'Spicy light soup with assorted meat and pounded fufu',
      imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400',
      price: 60.00, category: 'Stews',
    ),
    MenuItem(
      id: 'r2_m6', restaurantId: 'r2',
      name: 'Malta Guinness',
      description: 'Premium non-alcoholic malt drink, chilled',
      imageUrl: 'https://images.unsplash.com/photo-1534353436294-0dbd4bdac845?w=400',
      price: 10.00, category: 'Drinks',
    ),
  ];

  // ─── Chow Noodle menu ─────────────────────────────────────────────────────

  static const _chowMenu = [
    MenuItem(
      id: 'r3_m1', restaurantId: 'r3',
      name: 'Beef Lo Mein',
      description: 'Wok-tossed egg noodles with tender beef strips & vegetables',
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      price: 75.00, category: 'Noodles', isPopular: true,
    ),
    MenuItem(
      id: 'r3_m2', restaurantId: 'r3',
      name: 'Chicken Fried Rice',
      description: 'Wok-fried jasmine rice with chicken, egg & spring onion',
      imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
      price: 65.00, category: 'Fried Rice', isPopular: true,
    ),
    MenuItem(
      id: 'r3_m3', restaurantId: 'r3',
      name: 'Prawn Dim Sum (6 pcs)',
      description: 'Steamed crystal dumplings with prawn filling & dipping sauce',
      imageUrl: 'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=400',
      price: 85.00, category: 'Dim Sum',
    ),
    MenuItem(
      id: 'r3_m4', restaurantId: 'r3',
      name: 'Hot & Sour Soup',
      description: 'Traditional Cantonese soup with mushrooms & tofu',
      imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400',
      price: 45.00, category: 'Soups',
    ),
  ];

  // ─── Buka Joint menu ──────────────────────────────────────────────────────

  static const _bukaMenu = [
    MenuItem(
      id: 'r4_m1', restaurantId: 'r4',
      name: 'Fufu + Groundnut Soup',
      description: 'Hand-pounded fufu with rich groundnut soup & goat meat',
      imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
      price: 55.00, category: 'Fufu', isPopular: true,
    ),
    MenuItem(
      id: 'r4_m2', restaurantId: 'r4',
      name: 'Banku + Okro Stew',
      description: 'Smooth banku served with fresh okro stew & smoked fish',
      imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
      price: 48.00, category: 'Stews', isPopular: true,
    ),
    MenuItem(
      id: 'r4_m3', restaurantId: 'r4',
      name: 'Kenkey + Fried Fish',
      description: 'Fermented corn kenkey with fried tilapia & pepper sauce',
      imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
      price: 42.00, category: 'Stews',
    ),
    MenuItem(
      id: 'r4_m4', restaurantId: 'r4',
      name: 'Jollof Rice',
      description: 'Home-style jollof rice with beef & fried plantain',
      imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
      price: 50.00, category: 'Rice',
    ),
    MenuItem(
      id: 'r4_m5', restaurantId: 'r4',
      name: 'Sobolo (500ml)',
      description: 'Chilled hibiscus drink with ginger & cloves',
      imageUrl: 'https://images.unsplash.com/photo-1534353436294-0dbd4bdac845?w=400',
      price: 12.00, category: 'Drinks',
    ),
  ];

  // ─── Pizza Inn menu ───────────────────────────────────────────────────────

  static const _pizzaMenu = [
    MenuItem(
      id: 'r5_m1', restaurantId: 'r5',
      name: 'Pepperoni Pizza (Lg)',
      description: 'Loaded pepperoni on house tomato sauce & mozzarella',
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
      price: 115.00, category: 'Pizzas', isPopular: true,
    ),
    MenuItem(
      id: 'r5_m2', restaurantId: 'r5',
      name: 'BBQ Chicken Pizza (Md)',
      description: 'Tender chicken, BBQ sauce, onions & cheddar cheese',
      imageUrl: 'https://images.unsplash.com/photo-1571066811602-716837d681de?w=400',
      price: 95.00, category: 'Pizzas', isPopular: true,
    ),
    MenuItem(
      id: 'r5_m3', restaurantId: 'r5',
      name: 'Spaghetti Bolognese',
      description: 'Al dente spaghetti in rich meat & tomato sauce',
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400',
      price: 78.00, category: 'Pasta',
    ),
    MenuItem(
      id: 'r5_m4', restaurantId: 'r5',
      name: 'Garlic Bread (4 pcs)',
      description: 'Toasted baguette with garlic butter & herbs',
      imageUrl: 'https://images.unsplash.com/photo-1573140247632-f8fd74997d5c?w=400',
      price: 32.00, category: 'Sides',
    ),
    MenuItem(
      id: 'r5_m5', restaurantId: 'r5',
      name: 'Choc Lava Cake',
      description: 'Warm chocolate cake with molten centre & vanilla ice cream',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
      price: 45.00, category: 'Desserts',
    ),
  ];

  // ─── Marwako menu ─────────────────────────────────────────────────────────

  static const _marwakoMenu = [
    MenuItem(
      id: 'r6_m1', restaurantId: 'r6',
      name: 'Shawarma Wrap',
      description: 'Grilled chicken or beef with garlic sauce in flatbread',
      imageUrl: 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400',
      price: 45.00, category: 'Wraps', isPopular: true,
    ),
    MenuItem(
      id: 'r6_m2', restaurantId: 'r6',
      name: 'Chicken Fried Rice',
      description: 'Fragrant rice with tender chicken pieces',
      imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400',
      price: 55.00, category: 'Rice',
    ),
    MenuItem(
      id: 'r6_m3', restaurantId: 'r6',
      name: 'Mixed Grill Platter',
      description: 'Assorted grilled meats with sides and sauce',
      imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
      price: 140.00, category: 'Grills', isPopular: true,
    ),
  ];

  // ─── Burger Co. menu ──────────────────────────────────────────────────────

  static const _burgerMenu = [
    MenuItem(
      id: 'r7_m1', restaurantId: 'r7',
      name: 'Smash Burger (Double)',
      description: 'Double smashed patty, American cheese, pickles & special sauce',
      imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=400',
      price: 85.00, category: 'Burgers', isPopular: true,
    ),
    MenuItem(
      id: 'r7_m2', restaurantId: 'r7',
      name: 'Crispy Chicken Burger',
      description: 'Buttermilk fried chicken, slaw & chipotle aioli',
      imageUrl: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400',
      price: 72.00, category: 'Burgers', isPopular: true,
    ),
    MenuItem(
      id: 'r7_m3', restaurantId: 'r7',
      name: 'Loaded Fries',
      description: 'Crispy fries topped with cheese sauce, bacon & jalapeños',
      imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
      price: 38.00, category: 'Fries',
    ),
    MenuItem(
      id: 'r7_m4', restaurantId: 'r7',
      name: 'Oreo Shake',
      description: 'Thick blended Oreo milkshake with whipped cream',
      imageUrl: 'https://images.unsplash.com/photo-1572490122747-3e9be75fe09a?w=400',
      price: 48.00, category: 'Shakes',
    ),
  ];

  // ─── Healthy Bowl menu ────────────────────────────────────────────────────

  static const _healthyMenu = [
    MenuItem(
      id: 'r8_m1', restaurantId: 'r8',
      name: 'Acai Power Bowl',
      description: 'Frozen acai blend with granola, banana & fresh berries',
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400',
      price: 65.00, category: 'Bowls', isPopular: true,
    ),
    MenuItem(
      id: 'r8_m2', restaurantId: 'r8',
      name: 'Grilled Salmon Salad',
      description: 'Fresh salmon on a bed of mixed greens with lemon vinaigrette',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      price: 88.00, category: 'Salads', isPopular: true,
    ),
    MenuItem(
      id: 'r8_m3', restaurantId: 'r8',
      name: 'Green Detox Smoothie',
      description: 'Spinach, cucumber, ginger, lemon & apple blend',
      imageUrl: 'https://images.unsplash.com/photo-1610970881699-44a5587cabec?w=400',
      price: 42.00, category: 'Smoothies',
    ),
    MenuItem(
      id: 'r8_m4', restaurantId: 'r8',
      name: 'Chicken Caesar Wrap',
      description: 'Grilled chicken, romaine, parmesan & Caesar dressing in a whole-wheat wrap',
      imageUrl: 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400',
      price: 58.00, category: 'Wraps',
    ),
  ];
}
