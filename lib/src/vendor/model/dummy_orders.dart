import 'vendor_order.dart';

/// Dummy order data set — replace with API data when ready.
class DummyOrders {
  DummyOrders._();

  static final List<VendorOrder> all = [
    VendorOrder(
      id: '#BR-1024',
      items: 'Jollof Rice, Grilled Chicken, Kelewele',
      amount: 'GH\u20B5 85.00',
      timeAgo: '2 min ago',
      status: OrderStatus.newOrder,
      customerName: 'Kwame Mensah',
      customerPhone: '+233 24 123 4567',
      customerNote: 'Extra pepper on the side please',
      orderType: OrderType.delivery,
      itemList: [
        OrderItem(name: 'Jollof Rice (Large)', quantity: 1, price: 'GH\u20B5 35.00'),
        OrderItem(name: 'Grilled Chicken', quantity: 2, price: 'GH\u20B5 20.00'),
        OrderItem(name: 'Kelewele', quantity: 1, price: 'GH\u20B5 10.00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    VendorOrder(
      id: '#BR-1023',
      items: 'Waakye, Fish, Egg, Shito',
      amount: 'GH\u20B5 52.00',
      timeAgo: '8 min ago',
      status: OrderStatus.preparing,
      customerName: 'Ama Serwaa',
      customerPhone: '+233 50 987 6543',
      orderType: OrderType.delivery,
      itemList: [
        OrderItem(name: 'Waakye (Medium)', quantity: 1, price: 'GH\u20B5 25.00'),
        OrderItem(name: 'Fried Fish', quantity: 1, price: 'GH\u20B5 15.00'),
        OrderItem(name: 'Boiled Egg', quantity: 2, price: 'GH\u20B5 6.00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    VendorOrder(
      id: '#BR-1022',
      items: 'Banku, Tilapia, Pepper',
      amount: 'GH\u20B5 110.00',
      timeAgo: '15 min ago',
      status: OrderStatus.preparing,
      customerName: 'Kofi Asante',
      customerPhone: '+233 27 456 7890',
      customerNote: 'Make the pepper very hot!',
      orderType: OrderType.pickup,
      itemList: [
        OrderItem(name: 'Banku', quantity: 2, price: 'GH\u20B5 20.00'),
        OrderItem(name: 'Grilled Tilapia', quantity: 2, price: 'GH\u20B5 40.00'),
        OrderItem(name: 'Fresh Pepper (Hot)', quantity: 1, price: 'GH\u20B5 10.00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    VendorOrder(
      id: '#BR-1021',
      items: 'Fried Rice, Spring Rolls',
      amount: 'GH\u20B5 45.00',
      timeAgo: '22 min ago',
      status: OrderStatus.riderAssigned,
      customerName: 'Adjoa Poku',
      customerPhone: '+233 20 111 2233',
      orderType: OrderType.delivery,
      itemList: [
        OrderItem(name: 'Fried Rice (Large)', quantity: 1, price: 'GH\u20B5 35.00'),
        OrderItem(name: 'Spring Rolls (4 pcs)', quantity: 1, price: 'GH\u20B5 10.00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 22)),
    ),
    VendorOrder(
      id: '#BR-1020',
      items: 'Fufu, Light Soup, Goat Meat',
      amount: 'GH\u20B5 75.00',
      timeAgo: '35 min ago',
      status: OrderStatus.riderAssigned,
      customerName: 'Yaw Boateng',
      customerPhone: '+233 55 333 4455',
      customerNote: 'Please pack fufu and soup separately',
      orderType: OrderType.delivery,
      itemList: [
        OrderItem(name: 'Fufu', quantity: 1, price: 'GH\u20B5 20.00'),
        OrderItem(name: 'Light Soup', quantity: 1, price: 'GH\u20B5 15.00'),
        OrderItem(name: 'Goat Meat', quantity: 3, price: 'GH\u20B5 15.00', note: 'Soft pieces'),
      ],
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    VendorOrder(
      id: '#BR-1019',
      items: 'Red Red, Plantain',
      amount: 'GH\u20B5 30.00',
      timeAgo: '1 hr ago',
      status: OrderStatus.completed,
      customerName: 'Efua Dadzie',
      orderType: OrderType.pickup,
      itemList: [
        OrderItem(name: 'Red Red', quantity: 1, price: 'GH\u20B5 20.00'),
        OrderItem(name: 'Fried Plantain', quantity: 1, price: 'GH\u20B5 10.00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    VendorOrder(
      id: '#BR-1018',
      items: 'Kenkey, Fried Fish, Pepper',
      amount: 'GH\u20B5 40.00',
      timeAgo: '1.5 hrs ago',
      status: OrderStatus.completed,
      customerName: 'Nana Agyemang',
      orderType: OrderType.delivery,
      itemList: [
        OrderItem(name: 'Kenkey (Ga)', quantity: 2, price: 'GH\u20B5 12.00'),
        OrderItem(name: 'Fried Fish', quantity: 1, price: 'GH\u20B5 18.00'),
        OrderItem(name: 'Shito & Pepper', quantity: 1, price: 'GH\u20B5 10.00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    VendorOrder(
      id: '#BR-1017',
      items: 'Ampesi, Kontomire Stew',
      amount: 'GH\u20B5 38.00',
      timeAgo: '2 hrs ago',
      status: OrderStatus.cancelled,
      customerName: 'Abena Osei',
      customerNote: 'Cancelled — customer unreachable',
      orderType: OrderType.delivery,
      itemList: [
        OrderItem(name: 'Ampesi (Yam & Plantain)', quantity: 1, price: 'GH\u20B5 22.00'),
        OrderItem(name: 'Kontomire Stew', quantity: 1, price: 'GH\u20B5 16.00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static List<VendorOrder> get activeOrders =>
      all.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).toList();

  static List<VendorOrder> get newOrders =>
      all.where((o) => o.status == OrderStatus.newOrder).toList();

  static List<VendorOrder> byStatus(OrderStatus? status) =>
      status == null ? all : all.where((o) => o.status == status).toList();
}
