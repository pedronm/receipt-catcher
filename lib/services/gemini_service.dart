import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/receipt.dart';

/// Uses the Google Gemini API to extract structured data from a PDF receipt.
class GeminiService {
  static const String _modelName = 'gemini-1.5-flash';

  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
    );
  }

  /// Reads [pdfFile], sends it to Gemini and returns a parsed [Receipt].
  Future<Receipt> extractFromPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final mimeType = 'application/pdf';

    final prompt = _buildPrompt();

    final response = await _model.generateContent([
      Content.multi([
        DataPart(mimeType, bytes),
        TextPart(prompt),
      ]),
    ]);

    final text = response.text ?? '';
    return _parseResponse(text);
  }

  String _buildPrompt() => '''
You are a receipt parsing assistant. Analyze the provided PDF receipt and extract the following information.

Return your answer as a single valid JSON object (no markdown, no code fences) with this exact schema:
{
  "store_name": "string",
  "date": "YYYY-MM-DD",
  "subtotal": number,
  "tax": number,
  "total": number,
  "currency": "string (ISO 4217, e.g. USD, EUR, BRL)",
  "category": "string (one of: Food, Travel, Office, Health, Utilities, Entertainment, Other)",
  "notes": "string or null",
  "items": [
    {
      "description": "string",
      "quantity": number,
      "unit_price": number,
      "total_price": number
    }
  ]
}

Rules:
- All monetary values must be plain numbers (no currency symbols).
- If a field cannot be determined, use null for strings or 0 for numbers.
- The "date" must follow ISO 8601 (YYYY-MM-DD).
- Return ONLY the JSON object, nothing else.
''';

  Receipt _parseResponse(String responseText) {
    // Strip any accidental markdown fences
    final cleaned = responseText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return Receipt.fromJson(json);
    } catch (_) {
      // Return a placeholder receipt if parsing fails so the user can
      // manually fill in the details.
      return Receipt(
        storeName: 'Unknown Store',
        date: DateTime.now(),
        subtotal: 0,
        tax: 0,
        total: 0,
        notes: 'AI parsing failed – please fill in manually.',
      );
    }
  }
}
