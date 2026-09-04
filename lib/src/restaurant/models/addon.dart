/// Shared addon domain models used by both consumer and vendor sides.
library;

// ─── AddonOption ──────────────────────────────────────────────────────────────

class AddonOption {
  final String id;
  final String name;
  final double additionalPrice;
  final bool isAvailable;

  const AddonOption({
    required this.id,
    required this.name,
    required this.additionalPrice,
    this.isAvailable = true,
  });

  AddonOption copyWith({
    String? id,
    String? name,
    double? additionalPrice,
    bool? isAvailable,
  }) {
    return AddonOption(
      id: id ?? this.id,
      name: name ?? this.name,
      additionalPrice: additionalPrice ?? this.additionalPrice,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory AddonOption.fromJson(Map<String, dynamic> json) => AddonOption(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    additionalPrice: (json['additional_price'] as num? ?? 0).toDouble(),
    isAvailable: json['is_available'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'additional_price': additionalPrice,
    'is_available': isAvailable,
  };

  @override
  bool operator ==(Object other) => other is AddonOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─── AddonGroup ───────────────────────────────────────────────────────────────

class AddonGroup {
  final String id;
  final String name;
  final bool isRequired;

  /// Min number of options the consumer must pick.
  final int minSelections;

  /// 1 = radio (pick one), >1 = multi-select up to this count.
  final int maxSelections;

  final List<AddonOption> options;

  const AddonGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections = 1,
    required this.options,
  });

  AddonGroup copyWith({
    String? id,
    String? name,
    bool? isRequired,
    int? minSelections,
    int? maxSelections,
    List<AddonOption>? options,
  }) {
    return AddonGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      isRequired: isRequired ?? this.isRequired,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      options: options ?? this.options,
    );
  }

  factory AddonGroup.fromJson(Map<String, dynamic> json) => AddonGroup(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    isRequired: json['is_required'] as bool? ?? false,
    minSelections: json['min_selections'] as int? ?? 0,
    maxSelections: json['max_selections'] as int? ?? 1,
    options: (json['options'] as List<dynamic>? ?? [])
        .map((e) => AddonOption.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_required': isRequired,
    'min_selections': minSelections,
    'max_selections': maxSelections,
    'options': options.map((o) => o.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) => other is AddonGroup && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ─── SelectedAddon ────────────────────────────────────────────────────────────

/// Price-snapshot of a single addon choice stored inside [CartItem] and
/// [OrderItem]. Capturing the price at selection time prevents stale totals
/// if the vendor later edits the addon price.
class SelectedAddon {
  final String groupId;
  final String groupName;
  final String optionId;
  final String optionName;
  final double additionalPrice;

  /// How many units of this option the user chose (default 1).
  final int quantity;

  const SelectedAddon({
    required this.groupId,
    required this.groupName,
    required this.optionId,
    required this.optionName,
    required this.additionalPrice,
    this.quantity = 1,
  });

  /// Total price contribution of this addon (price × quantity).
  double get totalPrice => additionalPrice * quantity;

  SelectedAddon copyWith({
    String? groupId,
    String? groupName,
    String? optionId,
    String? optionName,
    double? additionalPrice,
    int? quantity,
  }) {
    return SelectedAddon(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      optionId: optionId ?? this.optionId,
      optionName: optionName ?? this.optionName,
      additionalPrice: additionalPrice ?? this.additionalPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  factory SelectedAddon.fromJson(Map<String, dynamic> json) => SelectedAddon(
    groupId: json['group_id'] as String? ?? '',
    groupName: json['group_name'] as String? ?? '',
    optionId: json['option_id']?.toString() ?? json['id']?.toString() ?? '',
    optionName:
        json['option_name'] as String? ?? json['name'] as String? ?? '',
    additionalPrice: (json['additional_price'] as num? ?? 0).toDouble(),
    quantity: json['quantity'] as int? ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'group_name': groupName,
    'option_id': optionId,
    'option_name': optionName,
    'additional_price': additionalPrice,
    'quantity': quantity,
  };

  @override
  bool operator ==(Object other) =>
      other is SelectedAddon &&
      other.groupId == groupId &&
      other.optionId == optionId;

  @override
  int get hashCode => Object.hash(groupId, optionId);
}
