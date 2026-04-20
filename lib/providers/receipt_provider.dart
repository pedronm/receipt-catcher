import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/sheets_service.dart';

enum ProviderStatus { idle, loading, error }

/// Central state container for the app.
class ReceiptProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final GeminiService _gemini = GeminiService();
  late final SheetsService _sheets = SheetsService(auth: _auth);

  final List<Receipt> _receipts = [];
  List<Receipt> get receipts => List.unmodifiable(_receipts);

  ProviderStatus _status = ProviderStatus.idle;
  ProviderStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _spreadsheetId = '';
  String get spreadsheetId => _spreadsheetId;

  bool get isSignedIn => _auth.isSignedIn;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _spreadsheetId = prefs.getString('spreadsheet_id') ?? '';
    final stored = prefs.getString('receipts');
    if (stored != null) {
      try {
        final list = jsonDecode(stored) as List<dynamic>;
        _receipts.addAll(
          list.map((e) => Receipt.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e) {
        // Corrupt cache – ignore and start fresh. In debug mode this surfaces
        // via Flutter's error reporter.
        assert(() {
          debugPrint('receipt_provider: failed to load cached receipts: $e');
          return true;
        }());
      }    }
    notifyListeners();
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<bool> signIn() async {
    _setStatus(ProviderStatus.loading);
    try {
      final account = await _auth.signIn();
      _setStatus(ProviderStatus.idle);
      return account != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> setSpreadsheetId(String id) async {
    _spreadsheetId = id.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spreadsheet_id', _spreadsheetId);
    notifyListeners();
  }

  // ── Receipt processing ────────────────────────────────────────────────────

  /// Sends [pdfFile] to Gemini and returns the extracted [Receipt].
  Future<Receipt?> processReceipt(File pdfFile) async {
    _setStatus(ProviderStatus.loading);
    try {
      final receipt = await _gemini.extractFromPdf(pdfFile);
      _setStatus(ProviderStatus.idle);
      return receipt;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Uploads [receipt] to Google Sheets and saves it locally.
  Future<bool> submitReceipt(Receipt receipt) async {
    if (_spreadsheetId.isEmpty) {
      _setError('No Spreadsheet ID configured. Go to Settings first.');
      return false;
    }
    _setStatus(ProviderStatus.loading);
    try {
      await _sheets.ensureSheetStructure(_spreadsheetId);
      await _sheets.appendReceipt(_spreadsheetId, receipt);
      final synced = receipt.copyWith(status: ReceiptStatus.synced);
      _receipts.insert(0, synced);
      await _persistReceipts();
      _setStatus(ProviderStatus.idle);
      return true;
    } catch (e) {
      // Save locally even if Sheets upload failed.
      _receipts.insert(0, receipt.copyWith(status: ReceiptStatus.error));
      await _persistReceipts();
      _setError(e.toString());
      return false;
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _persistReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'receipts',
      jsonEncode(_receipts.map((r) => r.toJson()).toList()),
    );
  }

  void _setStatus(ProviderStatus s) {
    _status = s;
    if (s != ProviderStatus.error) _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _status = ProviderStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }
}
