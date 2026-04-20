import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_catcher/models/receipt.dart';
import 'package:receipt_catcher/models/receipt_item.dart';

void main() {
  group('Receipt', () {
    test('generates a unique UUID id when none is provided', () {
      final r1 = Receipt(
        storeName: 'Test Store',
        date: DateTime(2025, 1, 15),
        subtotal: 10.0,
        tax: 1.0,
        total: 11.0,
      );
      final r2 = Receipt(
        storeName: 'Test Store',
        date: DateTime(2025, 1, 15),
        subtotal: 10.0,
        tax: 1.0,
        total: 11.0,
      );

      expect(r1.id, isNotEmpty);
      expect(r2.id, isNotEmpty);
      expect(r1.id, isNot(equals(r2.id)));
    });

    test('preserves provided id', () {
      const customId = '00000000-0000-0000-0000-000000000001';
      final receipt = Receipt(
        id: customId,
        storeName: 'Store',
        date: DateTime.now(),
        subtotal: 0,
        tax: 0,
        total: 0,
      );
      expect(receipt.id, equals(customId));
    });

    test('toSheetRow includes id as first column', () {
      final receipt = Receipt(
        storeName: 'Supermarket',
        date: DateTime(2025, 3, 10),
        subtotal: 50.0,
        tax: 5.0,
        total: 55.0,
        currency: 'USD',
        category: 'Food',
      );

      final row = receipt.toSheetRow();
      expect(row.first, equals(receipt.id));
      expect(row[1], equals('Supermarket'));
      expect(row[2], equals('2025-03-10'));
      expect(row[3], equals(50.0));
      expect(row[5], equals(55.0));
    });

    test('fromJson round-trips through toJson', () {
      final original = Receipt(
        storeName: 'Round Trip Store',
        date: DateTime(2025, 6, 20),
        subtotal: 20.0,
        tax: 2.0,
        total: 22.0,
        currency: 'EUR',
        category: 'Travel',
        notes: 'Business trip',
        items: [
          ReceiptItem(
            description: 'Train ticket',
            quantity: 1,
            unitPrice: 20.0,
            totalPrice: 20.0,
          ),
        ],
      );

      final json = original.toJson();
      final decoded = Receipt.fromJson(json);

      expect(decoded.id, equals(original.id));
      expect(decoded.storeName, equals(original.storeName));
      expect(decoded.total, equals(original.total));
      expect(decoded.currency, equals('EUR'));
      expect(decoded.items.length, equals(1));
      expect(decoded.items.first.description, equals('Train ticket'));
    });

    test('copyWith preserves id', () {
      final original = Receipt(
        storeName: 'Original',
        date: DateTime.now(),
        subtotal: 0,
        tax: 0,
        total: 0,
      );

      final copy = original.copyWith(storeName: 'Updated');
      expect(copy.id, equals(original.id));
      expect(copy.storeName, equals('Updated'));
    });
  });

  group('ReceiptItem', () {
    test('toSheetRow includes receiptId as first column', () {
      const receiptId = 'abc-123';
      final item = ReceiptItem(
        description: 'Coffee',
        quantity: 2,
        unitPrice: 3.5,
        totalPrice: 7.0,
      );

      final row = item.toSheetRow(receiptId);
      expect(row.first, equals(receiptId));
      expect(row[1], equals('Coffee'));
      expect(row[2], equals(2.0));
      expect(row[4], equals(7.0));
    });

    test('fromJson handles numeric strings gracefully', () {
      final item = ReceiptItem.fromJson({
        'description': 'Widget',
        'quantity': '3',
        'unit_price': '1.99',
        'total_price': '5.97',
      });

      expect(item.quantity, equals(3.0));
      expect(item.unitPrice, equals(1.99));
      expect(item.totalPrice, equals(5.97));
    });
  });

  group('Receipt sheetHeaders', () {
    test('first header is ID', () {
      expect(Receipt.sheetHeaders.first, equals('ID'));
    });

    test('itemSheetHeaders first column is Receipt ID', () {
      expect(Receipt.itemSheetHeaders.first, equals('Receipt ID'));
    });
  });
}
