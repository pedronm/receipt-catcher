import 'package:googleapis/sheets/v4.dart' as sheets;

import '../models/receipt.dart';
import 'auth_service.dart';

/// Manages all read/write operations against Google Sheets.
///
/// The spreadsheet is expected to have (at least) two tabs:
///   • **receipts** – one summary row per receipt, keyed on [Receipt.id].
///   • **items**    – one row per line-item, also keyed on [Receipt.id].
///
/// Both tabs share the same UUID primary key so data can be joined across
/// them (or referenced from other tabs / spreadsheets).
class SheetsService {
  static const String _receiptsTab = 'receipts';
  static const String _itemsTab = 'items';

  final AuthService _auth;

  SheetsService({AuthService? auth}) : _auth = auth ?? AuthService();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Ensures both required tabs exist and have the correct header rows.
  Future<void> ensureSheetStructure(String spreadsheetId) async {
    final api = await _getSheetsApi();

    final meta = await api.spreadsheets.get(spreadsheetId);
    final existingTitles = meta.sheets
            ?.map((s) => s.properties?.title ?? '')
            .toSet() ??
        <String>{};

    final requests = <sheets.Request>[];

    if (!existingTitles.contains(_receiptsTab)) {
      requests.add(_addSheetRequest(_receiptsTab));
    }
    if (!existingTitles.contains(_itemsTab)) {
      requests.add(_addSheetRequest(_itemsTab));
    }

    if (requests.isNotEmpty) {
      await api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: requests),
        spreadsheetId,
      );
    }

    // Write headers if the sheets are brand-new (empty).
    await _ensureHeaders(
      api,
      spreadsheetId,
      _receiptsTab,
      Receipt.sheetHeaders,
    );
    await _ensureHeaders(
      api,
      spreadsheetId,
      _itemsTab,
      Receipt.itemSheetHeaders,
    );
  }

  /// Appends [receipt] to the **receipts** tab and its line items to the
  /// **items** tab.  Both rows carry [Receipt.id] so they can be referenced
  /// across tabs.
  Future<void> appendReceipt(
    String spreadsheetId,
    Receipt receipt,
  ) async {
    final api = await _getSheetsApi();

    // 1. Summary row on the "receipts" tab.
    await _appendRow(
      api,
      spreadsheetId,
      _receiptsTab,
      receipt.toSheetRow().map(_cellValue).toList(),
    );

    // 2. One row per item on the "items" tab.
    for (final item in receipt.items) {
      await _appendRow(
        api,
        spreadsheetId,
        _itemsTab,
        item.toSheetRow(receipt.id).map(_cellValue).toList(),
      );
    }
  }

  /// Returns all receipt rows from the **receipts** tab (excluding header).
  Future<List<List<String>>> fetchReceiptRows(String spreadsheetId) async {
    final api = await _getSheetsApi();
    final response = await api.spreadsheets.values.get(
      spreadsheetId,
      '$_receiptsTab!A2:Z',
    );
    return (response.values ?? [])
        .map((row) => row.map((cell) => cell.toString()).toList())
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<sheets.SheetsApi> _getSheetsApi() async {
    final client = await _auth.getAuthClient();
    return sheets.SheetsApi(client);
  }

  sheets.Request _addSheetRequest(String title) {
    return sheets.Request(
      addSheet: sheets.AddSheetRequest(
        properties: sheets.SheetProperties(title: title),
      ),
    );
  }

  Future<void> _ensureHeaders(
    sheets.SheetsApi api,
    String spreadsheetId,
    String tab,
    List<String> headers,
  ) async {
    final range = '$tab!A1:${_columnLetter(headers.length)}1';
    final existing = await api.spreadsheets.values.get(
      spreadsheetId,
      range,
    );
    if (existing.values == null || existing.values!.isEmpty) {
      await api.spreadsheets.values.update(
        sheets.ValueRange(
          range: range,
          values: [headers],
        ),
        spreadsheetId,
        range,
        valueInputOption: 'RAW',
      );
    }
  }

  Future<void> _appendRow(
    sheets.SheetsApi api,
    String spreadsheetId,
    String tab,
    List<Object> row,
  ) async {
    final range = '$tab!A1';
    await api.spreadsheets.values.append(
      sheets.ValueRange(values: [row]),
      spreadsheetId,
      range,
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }

  /// Converts a value to the type expected by the Sheets API.
  Object _cellValue(Object value) {
    if (value is double || value is int) return value;
    return value.toString();
  }

  /// Converts a 1-based column index to a letter (1 → A, 9 → I, 26 → Z).
  String _columnLetter(int index) {
    var result = '';
    while (index > 0) {
      index--;
      result = String.fromCharCode(65 + index % 26) + result;
      index ~/= 26;
    }
    return result;
  }
}
