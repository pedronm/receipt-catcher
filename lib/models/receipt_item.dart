/// A single line item extracted from a receipt.
class ReceiptItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  const ReceiptItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      description: json['description'] as String? ?? '',
      quantity: _parseDouble(json['quantity']),
      unitPrice: _parseDouble(json['unit_price']),
      totalPrice: _parseDouble(json['total_price']),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };

  /// Converts this item to a Google Sheets row (list of values).
  List<Object> toSheetRow(String receiptId) => [
        receiptId,
        description,
        quantity,
        unitPrice,
        totalPrice,
      ];

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
