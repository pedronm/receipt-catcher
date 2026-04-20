# Receipt Catcher

A Flutter mobile app that lets you upload PDF receipts, extract their details via Google Gemini AI, and sync the data to a Google Sheets spreadsheet.

## Features

- **PDF upload** – pick any PDF receipt from your device.
- **AI extraction** – Gemini 1.5 Flash reads the PDF and extracts store name, date, subtotal, tax, total, currency, category, and line items.
- **Review & edit** – inspect every field before committing.
- **Google Sheets sync** – one tap writes to two tabs in your spreadsheet:
  - `receipts` – one summary row per receipt.
  - `items` – one row per line item.
- **Unique receipt ID** – every receipt gets a UUID v4 that is written to **both** tabs, enabling cross-tab / cross-spreadsheet references.
- **Local cache** – receipts are stored on-device so you can view them offline.

## Setup

### 1. Prerequisites

- [Flutter SDK ≥ 3.2](https://flutter.dev/docs/get-started/install)
- A Google Cloud project with:
  - **Google Sheets API** enabled
  - **OAuth 2.0** credentials configured for Android/iOS (add `google-services.json` for Android, `GoogleService-Info.plist` for iOS)
- A **Gemini API key** from [Google AI Studio](https://aistudio.google.com/)

### 2. Clone & install

```bash
git clone https://github.com/pedronm/receipt-catcher.git
cd receipt-catcher
flutter pub get
```

### 3. Configure environment

Copy `.env.example` to `.env` and fill in your Gemini API key:

```
GEMINI_API_KEY=your_key_here
```

### 4. Run

```bash
flutter run
```

## Architecture

```
lib/
├── main.dart                  # Entry point
├── theme.dart                 # Light Material 3 theme
├── models/
│   ├── receipt.dart           # Receipt model + UUID id
│   └── receipt_item.dart      # Line item model
├── services/
│   ├── auth_service.dart      # Google Sign-In + authenticated HTTP client
│   ├── gemini_service.dart    # PDF → structured JSON via Gemini
│   └── sheets_service.dart    # Google Sheets read/write
├── providers/
│   └── receipt_provider.dart  # ChangeNotifier state container
├── screens/
│   ├── home_screen.dart
│   ├── upload_screen.dart
│   ├── receipt_detail_screen.dart
│   └── settings_screen.dart
└── widgets/
    └── receipt_card.dart
```

## Google Sheets structure

| Tab        | Columns |
|------------|---------|
| `receipts` | ID · Store · Date · Subtotal · Tax · Total · Currency · Category · Notes |
| `items`    | Receipt ID · Description · Quantity · Unit Price · Total Price |

Both tabs share the same **UUID** (`Receipt.id`) as a foreign key, so you can use `VLOOKUP` / `QUERY` to join them, or reference a receipt from any other tab in the same (or a different) spreadsheet.

