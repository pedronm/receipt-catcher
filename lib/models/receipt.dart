import 'package:uuid/uuid.dart';
import 'receipt_item.dart';

enum ReceiptStatus { pending, synced, error }

/// Represents a single receipt parsed from a PDF.
///
/// The [id] (UUID v4) acts as the primary key and is used as a cross-table
/// reference in Google Sheets (e.g. a "receipts" summary tab and an
/// "items" detail tab both keyed on the same [id]).
class Receipt {
  /// Universally-unique identifier – written to every Sheets row for
  /// cross-tab / cross-table referencing.
  final String id;

  final String storeName;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double total;
  final String currency;
  final String? category;
  final String? notes;
  final List<ReceiptItem> items;

  ReceiptStatus status;

  Receipt({
    String? id,
    required this.storeName,
    required this.date,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.currency = 'USD',
    this.category,
    this.notes,
    this.items = const [],
    this.status = ReceiptStatus.pending,
  }) : id = id ?? const Uuid().v4();

  /// Header row for the "receipts" summary sheet tab.
  static List<String> get sheetHeaders => [
        'ID',
        'Store',
        'Date',
        'Subtotal',
        'Tax',
        'Total',
        'Currency',
        'Category',
        'Notes',
      ];

  /// Header row for the "items" detail sheet tab.
  static List<String> get itemSheetHeaders => [
        'Receipt ID',
        'Description',
        'Quantity',
        'Unit Price',
        'Total Price',
      ];

  /// Converts this receipt to a Google Sheets row for the summary tab.
  List<Object> toSheetRow() => [
        id,
        storeName,
        _formatDate(date),
        subtotal,
        tax,
        total,
        currency,
        category ?? '',
        notes ?? '',
      ];

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String?,
      storeName: json['store_name'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      subtotal: _parseDouble(json['subtotal']),
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
      currency: json['currency'] as String? ?? 'USD',
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'store_name': storeName,
        'date': date.toIso8601String(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'currency': currency,
        'category': category,
        'notes': notes,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
      };

  Receipt copyWith({
    String? storeName,
    DateTime? date,
    double? subtotal,
    double? tax,
    double? total,
    String? currency,
    String? category,
    String? notes,
    List<ReceiptItem>? items,
    ReceiptStatus? status,
  }) {
    return Receipt(
      id: id,
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
