# Spender Helper

Native iPhone app for logging spending after Apple Wallet payments, triggered via Shortcuts, with CSV export for Excel and Google Sheets.

## Requirements

- Mac with **Xcode 15+**
- iPhone running **iOS 17+**
- Apple ID / Developer account for on-device install and automations

## Open and run

1. Copy this folder to your Mac (or open from iCloud/cloud sync).
2. Open `SpenderHelper.xcodeproj` in Xcode.
3. Select the **SpenderHelper** target → **Signing & Capabilities** → set your **Team** and unique bundle ID if needed.
4. Connect your iPhone, select it as the run destination, press **Run**.
5. Add a **1024×1024** app icon in `SpenderHelper/Assets.xcassets/AppIcon` (placeholder is empty).

> Personal automations (Wallet closed) must be tested on a **physical iPhone**, not the Simulator.

## What the app does

- **Quick log** — Amount, merchant, category, card/account, date & time (defaults to now, editable), and notes after a payment.
- **Bank CSV import** — Import Caixa *Consulta de movimentos* CSV from **Settings → Import Bank CSV**. Updates account balances and syncs **expense (debit) rows only**; manual entries are left unchanged.
- **Balance sheet** — After import, accounting/available balances and statement period appear at the top of the expense list.
- **Categories** — Add and remove custom categories in **Settings → Categories** (default set seeded on first launch).
- **Cards & accounts** — Add and remove payment methods in **Settings → Cards & Accounts** (e.g. `Visa ••1234`).
- **Filters** — Filter the expense list by time period (today, this week, this month, last 30 days, or custom range), categories, and accounts. Export respects active filters.
- **History** — List, swipe to delete, tap to edit.
- **Export** — CSV with columns: `date`, `time`, `amount`, `currency`, `merchant`, `category`, `account`, `notes` (decimal point always `.` for spreadsheet compatibility).

Apple does **not** expose Wallet / Apple Pay transaction details to third-party apps. You enter the amount and merchant yourself.

## Wallet → log expense (Shortcuts automation)

1. On iPhone, open **Shortcuts** → **Automation** tab → **+**.
2. Choose **App**.
3. Tap **Choose** → select **Wallet**.
4. Select **Is Closed**.
5. Tap **Run Immediately** (required so it runs without tapping each time).
6. Optionally turn off **Notify When Run**.
7. Tap **Next**, then add one of:
   - **Open App** → **Spender Helper** (opens the app; tap **+** to log), or
   - **Log Expense** (from Spender Helper in the action list) — opens the quick-entry form directly.
8. Finish and enable the automation.

### Typical flow

1. Pay with Apple Wallet.
2. Leave the Wallet app.
3. Automation runs → Spender Helper opens (or shows the log form).
4. Enter amount and merchant → **Save** or **Save & Add Another**.

## Shortcuts actions (App Intents)

Available in the Shortcuts app under **Spender Helper**:

| Action | Description |
|--------|-------------|
| **Log Expense** | Opens the app to the quick-entry form |
| **Export Expenses** | Returns a CSV file (use **Save File** or **Share** in the next shortcut steps) |

Example export shortcut:

1. **Export Expenses** (Spender Helper).
2. **Save File** → iCloud Drive / On My iPhone.
3. Open the file in Excel, or import into Google Sheets.

## Import bank statement (Caixa CSV)

1. Export **Consulta de movimentos** from your bank (semicolon-separated CSV).
2. Open **Settings → Import Bank CSV** → **Browse Files** or **Choose CSV File**.
3. Optionally link the file to a specific account; otherwise the app matches by account number in the file.
4. The import will:
   - Store **Saldo contabilístico** and **Saldo disponível** on the account
   - Add/update/remove **bank-imported expenses** (negative amounts only)
   - Skip credits/transfers in (positive amounts)
   - Never modify expenses you logged manually

Re-importing the same file updates existing bank rows and removes bank rows that are no longer in the export.

## Export from the app

1. Open Spender Helper → tap **Export** (share icon) in the toolbar.
2. Share via Files, Mail, AirDrop, etc.
3. Filename pattern: `expenses-YYYYMMDD-HHmmss.csv`.

## Open in Excel

1. Save the CSV to Files or receive via AirDrop/email.
2. Open with **Microsoft Excel** (or Numbers).
3. Columns import as separate fields; amounts use a `.` decimal separator.

## Import into Google Sheets

**From the Google Sheets app (iPhone):**

1. Create or open a spreadsheet.
2. **Insert** or menu → **Import** → upload/select the CSV from Files.
3. Choose import location (new sheet or replace/append as offered).

**From Google Drive (desktop or web):**

1. Upload the CSV to Drive.
2. Open with Google Sheets → **File → Import** if needed.

**Optional Shortcuts semi-automation (no Google SDK in app):**

After **Export Expenses**, add Google’s **Add Row to Spreadsheet** action (requires Google account in Shortcuts). Map columns manually to match: date, time, amount, currency, merchant, category, notes.

## CSV format example

```csv
date,time,amount,currency,merchant,category,account,notes
2026-06-01,14:32:00,12.50,USD,Starbucks,Food,Visa ••1234,
```

## Project structure

```
SpenderHelper/
  SpenderHelperApp.swift      App entry + SwiftData container
  Models/                     Expense, Category, Account
  Views/                      Quick log, list, edit, share
  Services/                   DataController, CsvExportService
  Intents/                    Log Expense, Export Expenses, App Shortcuts
  Helpers/                    Launch flags for Shortcuts
```

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| Automation does not run | Confirm **Run Immediately**; disable Focus restrictions; test on device |
| “Log Expense” not in Shortcuts | Run the app once from Xcode; check iOS 17+ |
| Export intent says no expenses | Log at least one expense in the app first |
| EU decimal entry | Type `12,50` or `12.50` in the amount field; CSV export always uses `.` |

## License

Private use — adjust as needed for your project.
