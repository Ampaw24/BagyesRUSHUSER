import 'earnings_data.dart';

abstract final class DummyEarnings {
  static EarningsData getForPeriod(String period) => switch (period) {
        'today' => _today,
        'week' => _week,
        'month' => _month,
        _ => _all,
      };

  // ── Top selling items (shared across periods) ──

  static const _topItems = [
    TopSellingItem(
      name: 'Jollof Rice & Chicken',
      orderCount: 1245,
      revenue: 'GH₵ 37,350',
      category: 'Meals',
    ),
    TopSellingItem(
      name: 'Waakye Special',
      orderCount: 980,
      revenue: 'GH₵ 34,300',
      category: 'Meals',
    ),
    TopSellingItem(
      name: 'Banku & Tilapia',
      orderCount: 856,
      revenue: 'GH₵ 47,080',
      category: 'Meals',
    ),
    TopSellingItem(
      name: 'Fried Rice & Chicken',
      orderCount: 743,
      revenue: 'GH₵ 26,005',
      category: 'Meals',
    ),
    TopSellingItem(
      name: 'Fufu & Light Soup',
      orderCount: 612,
      revenue: 'GH₵ 27,540',
      category: 'Meals',
    ),
  ];

  // ── Payouts ──

  static const _payouts = [
    PayoutRecord(
      id: 'pay_001',
      amount: 'GH₵ 2,850.00',
      date: 'Processing since Mar 5',
      status: 'processing',
      method: 'Mobile Money',
      reference: 'PAY-8856',
    ),
    PayoutRecord(
      id: 'pay_002',
      amount: 'GH₵ 5,000.00',
      date: 'Mar 1, 2025',
      status: 'completed',
      method: 'Mobile Money',
      reference: 'PAY-8847',
    ),
    PayoutRecord(
      id: 'pay_003',
      amount: 'GH₵ 3,200.00',
      date: 'Feb 22, 2025',
      status: 'completed',
      method: 'Bank Transfer',
      reference: 'PAY-8831',
    ),
    PayoutRecord(
      id: 'pay_004',
      amount: 'GH₵ 4,500.00',
      date: 'Feb 15, 2025',
      status: 'completed',
      method: 'Mobile Money',
      reference: 'PAY-8819',
    ),
  ];

  // ── Today's transactions ──

  static const _todayTransactions = [
    Transaction(
      id: 'txn_001',
      orderId: '#ORD-2847',
      amount: 'GH₵ 85.50',
      date: 'Today, 2:45 PM',
      type: 'credit',
      customerName: 'Kwame Asante',
      paymentMethod: 'mobile_money',
    ),
    Transaction(
      id: 'txn_002',
      orderId: '#ORD-2846',
      amount: 'GH₵ 42.00',
      date: 'Today, 1:30 PM',
      type: 'credit',
      customerName: 'Ama Mensah',
      paymentMethod: 'card',
    ),
    Transaction(
      id: 'txn_003',
      orderId: 'Platform Fee',
      amount: 'GH₵ 8.55',
      date: 'Today, 1:00 PM',
      type: 'debit',
      paymentMethod: 'platform_fee',
    ),
    Transaction(
      id: 'txn_004',
      orderId: '#ORD-2845',
      amount: 'GH₵ 65.00',
      date: 'Today, 12:15 PM',
      type: 'credit',
      customerName: 'Kofi Boateng',
      paymentMethod: 'mobile_money',
    ),
    Transaction(
      id: 'txn_005',
      orderId: '#ORD-2844',
      amount: 'GH₵ 38.50',
      date: 'Today, 11:45 AM',
      type: 'credit',
      customerName: 'Abena Darkwa',
      paymentMethod: 'cash',
    ),
    Transaction(
      id: 'txn_006',
      orderId: 'Platform Fee',
      amount: 'GH₵ 6.50',
      date: 'Today, 11:00 AM',
      type: 'debit',
      paymentMethod: 'platform_fee',
    ),
    Transaction(
      id: 'txn_007',
      orderId: '#ORD-2843',
      amount: 'GH₵ 120.00',
      date: 'Today, 10:30 AM',
      type: 'credit',
      customerName: 'Yaw Frimpong',
      paymentMethod: 'mobile_money',
    ),
    Transaction(
      id: 'txn_008',
      orderId: '#ORD-2842',
      amount: 'GH₵ 55.00',
      date: 'Today, 9:45 AM',
      type: 'credit',
      customerName: 'Efua Mensah',
      paymentMethod: 'card',
    ),
    Transaction(
      id: 'txn_009',
      orderId: 'Withdrawal',
      amount: 'GH₵ 500.00',
      date: 'Today, 9:00 AM',
      type: 'debit',
      paymentMethod: 'mobile_money',
    ),
    Transaction(
      id: 'txn_010',
      orderId: '#ORD-2841',
      amount: 'GH₵ 28.00',
      date: 'Today, 8:30 AM',
      type: 'credit',
      customerName: 'Kwesi Appiah',
      paymentMethod: 'cash',
    ),
  ];

  // ── Week's transactions ──

  static const _weekTransactions = [
    ..._todayTransactions,
    Transaction(
      id: 'txn_011',
      orderId: '#ORD-2840',
      amount: 'GH₵ 95.00',
      date: 'Yesterday, 7:30 PM',
      type: 'credit',
      customerName: 'Akosua Boateng',
      paymentMethod: 'mobile_money',
    ),
    Transaction(
      id: 'txn_012',
      orderId: '#ORD-2839',
      amount: 'GH₵ 72.50',
      date: 'Yesterday, 5:15 PM',
      type: 'credit',
      customerName: 'Nana Osei',
      paymentMethod: 'card',
    ),
    Transaction(
      id: 'txn_013',
      orderId: 'Platform Fee',
      amount: 'GH₵ 16.75',
      date: 'Yesterday, 11:00 PM',
      type: 'debit',
      paymentMethod: 'platform_fee',
    ),
    Transaction(
      id: 'txn_014',
      orderId: '#ORD-2838',
      amount: 'GH₵ 48.00',
      date: 'Mar 4, 3:20 PM',
      type: 'credit',
      customerName: 'Adjoa Mensah',
      paymentMethod: 'mobile_money',
    ),
    Transaction(
      id: 'txn_015',
      orderId: '#ORD-2837',
      amount: 'GH₵ 156.00',
      date: 'Mar 4, 1:10 PM',
      type: 'credit',
      customerName: 'Kojo Annan',
      paymentMethod: 'mobile_money',
    ),
    Transaction(
      id: 'txn_016',
      orderId: '#ORD-2836',
      amount: 'GH₵ 34.00',
      date: 'Mar 3, 6:45 PM',
      type: 'credit',
      customerName: 'Esi Owusu',
      paymentMethod: 'cash',
    ),
    Transaction(
      id: 'txn_017',
      orderId: 'Platform Fee',
      amount: 'GH₵ 23.80',
      date: 'Mar 3, 11:00 PM',
      type: 'debit',
      paymentMethod: 'platform_fee',
    ),
    Transaction(
      id: 'txn_018',
      orderId: '#ORD-2835',
      amount: 'GH₵ 88.00',
      date: 'Mar 2, 2:00 PM',
      type: 'credit',
      customerName: 'Fiifi Baiden',
      paymentMethod: 'card',
    ),
  ];

  // ── Chart data per period ──

  static const _todayChart = [
    DailyRevenue(label: '8AM', amount: 28, orderCount: 1),
    DailyRevenue(label: '10AM', amount: 175, orderCount: 3),
    DailyRevenue(label: '12PM', amount: 310, orderCount: 6),
    DailyRevenue(label: '1PM', amount: 245, orderCount: 5),
    DailyRevenue(label: '2PM', amount: 195, orderCount: 4),
    DailyRevenue(label: '3PM', amount: 170, orderCount: 3),
    DailyRevenue(label: '4PM', amount: 127, orderCount: 2),
  ];

  static const _weekChart = [
    DailyRevenue(label: 'Mon', amount: 850, orderCount: 32),
    DailyRevenue(label: 'Tue', amount: 1200, orderCount: 45),
    DailyRevenue(label: 'Wed', amount: 980, orderCount: 38),
    DailyRevenue(label: 'Thu', amount: 1450, orderCount: 54),
    DailyRevenue(label: 'Fri', amount: 1800, orderCount: 67),
    DailyRevenue(label: 'Sat', amount: 2100, orderCount: 76),
    DailyRevenue(label: 'Sun', amount: 1050, orderCount: 40),
  ];

  static const _monthChart = [
    DailyRevenue(label: 'Wk 1', amount: 6800, orderCount: 256),
    DailyRevenue(label: 'Wk 2', amount: 8200, orderCount: 310),
    DailyRevenue(label: 'Wk 3', amount: 9700, orderCount: 365),
    DailyRevenue(label: 'Wk 4', amount: 9500, orderCount: 353),
  ];

  static const _allChart = [
    DailyRevenue(label: 'Oct', amount: 22400, orderCount: 845),
    DailyRevenue(label: 'Nov', amount: 25600, orderCount: 967),
    DailyRevenue(label: 'Dec', amount: 31200, orderCount: 1178),
    DailyRevenue(label: 'Jan', amount: 28400, orderCount: 1072),
    DailyRevenue(label: 'Feb', amount: 30800, orderCount: 1162),
    DailyRevenue(label: 'Mar', amount: 18400, orderCount: 623),
  ];

  // ── Period data ──

  static const _today = EarningsData(
    totalRevenue: 'GH₵ 156,800',
    todayRevenue: 'GH₵ 1,250',
    weekRevenue: 'GH₵ 8,430',
    monthRevenue: 'GH₵ 34,200',
    pendingPayout: 'GH₵ 2,850',
    totalOrders: 48,
    completedOrders: 45,
    cancelledOrders: 3,
    avgOrderValue: 'GH₵ 26.04',
    completionRate: 93.8,
    revenueGrowth: 12.5,
    chartData: _todayChart,
    transactions: _todayTransactions,
    payouts: _payouts,
    topItems: _topItems,
  );

  static const _week = EarningsData(
    totalRevenue: 'GH₵ 156,800',
    todayRevenue: 'GH₵ 1,250',
    weekRevenue: 'GH₵ 8,430',
    monthRevenue: 'GH₵ 34,200',
    pendingPayout: 'GH₵ 2,850',
    totalOrders: 312,
    completedOrders: 296,
    cancelledOrders: 16,
    avgOrderValue: 'GH₵ 27.02',
    completionRate: 94.9,
    revenueGrowth: 8.2,
    chartData: _weekChart,
    transactions: _weekTransactions,
    payouts: _payouts,
    topItems: _topItems,
  );

  static const _month = EarningsData(
    totalRevenue: 'GH₵ 156,800',
    todayRevenue: 'GH₵ 1,250',
    weekRevenue: 'GH₵ 8,430',
    monthRevenue: 'GH₵ 34,200',
    pendingPayout: 'GH₵ 2,850',
    totalOrders: 1284,
    completedOrders: 1215,
    cancelledOrders: 69,
    avgOrderValue: 'GH₵ 26.64',
    completionRate: 94.6,
    revenueGrowth: 15.3,
    chartData: _monthChart,
    transactions: _weekTransactions,
    payouts: _payouts,
    topItems: _topItems,
  );

  static const _all = EarningsData(
    totalRevenue: 'GH₵ 156,800',
    todayRevenue: 'GH₵ 1,250',
    weekRevenue: 'GH₵ 8,430',
    monthRevenue: 'GH₵ 34,200',
    pendingPayout: 'GH₵ 2,850',
    totalOrders: 5847,
    completedOrders: 5562,
    cancelledOrders: 285,
    avgOrderValue: 'GH₵ 26.81',
    completionRate: 95.1,
    revenueGrowth: 22.4,
    chartData: _allChart,
    transactions: _weekTransactions,
    payouts: _payouts,
    topItems: _topItems,
  );
}
