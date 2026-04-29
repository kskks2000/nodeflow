class TransportOrderStopRequest {
  const TransportOrderStopRequest({
    required this.locationName,
    required this.address1,
    this.address2,
    this.contactName,
    this.contactPhone,
    this.requestedArrivalFrom,
    this.requestedArrivalTo,
    this.workNote,
  });

  final String locationName;
  final String address1;
  final String? address2;
  final String? contactName;
  final String? contactPhone;
  final DateTime? requestedArrivalFrom;
  final DateTime? requestedArrivalTo;
  final String? workNote;

  Map<String, Object?> toJson() {
    return {
      'location_name': locationName,
      'address1': address1,
      'address2': address2,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'requested_arrival_from': requestedArrivalFrom?.toIso8601String(),
      'requested_arrival_to': requestedArrivalTo?.toIso8601String(),
      'work_note': workNote,
    };
  }
}

class TransportOrderItemRequest {
  const TransportOrderItemRequest({
    required this.itemName,
    this.packageType,
    this.qty = 1,
    this.weightKg = 0,
    this.volumeCbm = 0,
    this.pallets = 0,
    this.temperatureType,
    this.isHazardous = false,
    this.handlingNote,
  });

  final String itemName;
  final String? packageType;
  final double qty;
  final double weightKg;
  final double volumeCbm;
  final double pallets;
  final String? temperatureType;
  final bool isHazardous;
  final String? handlingNote;

  Map<String, Object?> toJson() {
    return {
      'item_name': itemName,
      'package_type': packageType,
      'qty': qty,
      'weight_kg': weightKg,
      'volume_cbm': volumeCbm,
      'pallets': pallets,
      'temperature_type': temperatureType,
      'is_hazardous': isHazardous,
      'handling_note': handlingNote,
    };
  }
}

class TransportOrderCreateRequest {
  const TransportOrderCreateRequest({
    this.orderNo,
    required this.customerName,
    this.customerCode,
    this.customerOrderNo,
    required this.orderType,
    required this.serviceLevel,
    required this.confirm,
    required this.orderDate,
    this.requestedPickupAt,
    this.requestedDeliveryAt,
    this.requiredVehicleType,
    this.requiredTonClass,
    this.temperatureType,
    this.isExclusive = false,
    this.isEmergency = false,
    required this.totalQty,
    required this.totalWeightKg,
    required this.totalVolumeCbm,
    required this.totalPallets,
    this.specialInstructions,
    required this.pickup,
    required this.delivery,
    required this.item,
  });

  final String? orderNo;
  final String customerName;
  final String? customerCode;
  final String? customerOrderNo;
  final String orderType;
  final String serviceLevel;
  final bool confirm;
  final DateTime orderDate;
  final DateTime? requestedPickupAt;
  final DateTime? requestedDeliveryAt;
  final String? requiredVehicleType;
  final double? requiredTonClass;
  final String? temperatureType;
  final bool isExclusive;
  final bool isEmergency;
  final double totalQty;
  final double totalWeightKg;
  final double totalVolumeCbm;
  final double totalPallets;
  final String? specialInstructions;
  final TransportOrderStopRequest pickup;
  final TransportOrderStopRequest delivery;
  final TransportOrderItemRequest item;

  Map<String, Object?> toJson() {
    return {
      'order_no': orderNo,
      'customer_name': customerName,
      'customer_code': customerCode,
      'customer_order_no': customerOrderNo,
      'order_type': orderType,
      'service_level': serviceLevel,
      'confirm': confirm,
      'order_date': _dateOnly(orderDate),
      'requested_pickup_at': requestedPickupAt?.toIso8601String(),
      'requested_delivery_at': requestedDeliveryAt?.toIso8601String(),
      'required_vehicle_type': requiredVehicleType,
      'required_ton_class': requiredTonClass,
      'temperature_type': temperatureType,
      'is_exclusive': isExclusive,
      'is_emergency': isEmergency,
      'total_qty': totalQty,
      'total_weight_kg': totalWeightKg,
      'total_volume_cbm': totalVolumeCbm,
      'total_pallets': totalPallets,
      'special_instructions': specialInstructions,
      'pickup': pickup.toJson(),
      'delivery': delivery.toJson(),
      'item': item.toJson(),
    };
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class TransportOrderResponse {
  const TransportOrderResponse({
    required this.orderId,
    required this.orderNo,
    required this.customerId,
    required this.customerName,
    required this.statusCode,
    required this.orderDate,
    this.requestedPickupAt,
    this.requestedDeliveryAt,
    required this.createdAt,
    this.acceptedAt,
  });

  final int orderId;
  final String orderNo;
  final int customerId;
  final String customerName;
  final String statusCode;
  final DateTime orderDate;
  final DateTime? requestedPickupAt;
  final DateTime? requestedDeliveryAt;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  factory TransportOrderResponse.fromJson(Map<String, Object?> json) {
    return TransportOrderResponse(
      orderId: json['order_id'] as int,
      orderNo: json['order_no'] as String,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String,
      statusCode: json['status_code'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      requestedPickupAt: _dateTimeOrNull(json['requested_pickup_at']),
      requestedDeliveryAt: _dateTimeOrNull(json['requested_delivery_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: _dateTimeOrNull(json['accepted_at']),
    );
  }
}

class TransportOrderFailure implements Exception {
  const TransportOrderFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
