---
name: internationalization
description: >
  Pattern guide and workflow for Flutter internationalization (i18n) supporting
  English and Gujarati in the mithai_wale project. Read this skill before adding
  or editing any UI component, titles, button labels, messages, or ARB files.
---

# Internationalization (i18n) Skill Guide

This skill details how to manage strings, translations, and locale switching in the **Mithai Wale** project.

Supported Locales:
- `en` — English
- `gu` — Gujarati (`ગુજરાતી`)

---

## 1. Architecture Overview

```
mithai_wale/
├── l10n.yaml                           ← l10n build config
├── lib/
│   ├── l10n/
│   │   ├── app_en.arb                  ← English source template & descriptions
│   │   ├── app_gu.arb                  ← Gujarati translations
│   │   ├── l10n.dart                   ← Context extension (context.l10n)
│   │   └── generated/                  ← Code-generated classes
│   │       ├── app_localizations.dart
│   │       ├── app_localizations_en.dart
│   │       └── app_localizations_gu.dart
│   ├── core/
│   │   └── state/
│   │       └── app_state_providers.dart ← localeProvider (persisted via Hive)
│   └── main.dart                       ← Hooked to MaterialApp.router
```

---

## 2. Accessing Strings in Widgets

Always import the helper extension:
```dart
import 'package:mithai_wale/l10n/l10n.dart';
```

Use `context.l10n.<key>` in widget trees:

### Basic Text / AppBar Title
```dart
AppBar(
  title: Text(context.l10n.navSettings),
)
```

### Buttons (Remember Button Elevation Rule!)
```dart
FilledButton.icon(
  onPressed: _saveChanges,
  icon: const Icon(Icons.check),
  label: Text(context.l10n.actionSave),
)
```

### Parameterized Strings
```dart
// app_en.arb: "pricePerUnit": "₹{price} / {unit}"
Text(context.l10n.pricePerUnit('450', 'kg'))
```

### Pluralization
```dart
// app_en.arb: "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}"
Text(context.l10n.itemCount(items.length))
```

---

## 3. Adding New Strings (Step-by-Step)

Follow this 4-step workflow whenever introducing new labels or titles:

### Step 1: Add to `lib/l10n/app_en.arb`
Add the key and its definition with metadata description:
```json
"navCheckout": "Checkout",
"@navCheckout": {
  "description": "Navigation label for checkout"
},
"deliveryAddress": "Delivery Address",
"@deliveryAddress": {
  "description": "Label for customer delivery address field"
}
```

### Step 2: Add to `lib/l10n/app_gu.arb`
Add the exact matching key with Gujarati translation:
```json
"navCheckout": "ચેકઆઉટ",
"deliveryAddress": "ડિલિવરી સરનામું"
```

### Step 3: Run Generation
Run the Flutter localization generator:
```powershell
flutter gen-l10n
```
This updates `lib/l10n/generated/app_localizations.dart`.

### Step 4: Use in Component
```dart
Text(context.l10n.deliveryAddress)
```

---

## 4. Key Naming Standards

Follow consistent prefixes:
- `nav<Screen>` — Navigation destinations (`navHome`, `navShop`, `navOrders`, `navProfile`, `navSettings`, `navCart`)
- `action<Verb>` — Buttons and interactive actions (`actionSave`, `actionCancel`, `actionEdit`, `actionDelete`, `actionConfirm`)
- `status<State>` — Status badges and chips (`statusPending`, `statusCompleted`, `statusCancelled`)
- `<feature><Element>` — Feature-scoped titles/labels (`storeName`, `menuCatalogManagement`, `searchSweets`)

---

## 5. Language Switching & State Management

The active locale is managed globally by `localeProvider` in `lib/core/state/app_state_providers.dart`:

```dart
// Read current locale
final currentLocale = ref.watch(localeProvider).valueOrNull;

// Switch to Gujarati
ref.read(localeProvider.notifier).setLocale(const Locale('gu'));

// Switch to English
ref.read(localeProvider.notifier).setLocale(const Locale('en'));

// Reset to System default
ref.read(localeProvider.notifier).setLocale(null);
```

The preference is automatically persisted to local storage (`HiveSettingsRepository`).
