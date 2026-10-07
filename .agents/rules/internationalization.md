# Internationalization (i18n) Rule

## Core Requirement
Every user-facing string across the application—including page headers, component titles, button labels, form placeholders, dialogs, snackbars, and tooltips—must be localized through Flutter's internationalization system (`AppLocalizations`). Hardcoding raw user-facing text strings directly in widgets is strictly forbidden.

Currently supported languages:
- **English (`en`)** — Default
- **Gujarati (`gu`)** — `ગુજરાતી`

---

## 1. No Hardcoded Strings in Components
❌ **Never write raw strings in UI widgets**:
```dart
// BAD
Text('Settings')
ElevatedButton(child: Text('Save'), ...)
TextField(decoration: InputDecoration(hintText: 'Search sweets...'))
```

✅ **Always use `context.l10n.<key>`**:
```dart
// GOOD
import 'package:mithai_wale/l10n/l10n.dart';

Text(context.l10n.navSettings)
ElevatedButton(child: Text(context.l10n.actionSave), ...)
TextField(decoration: InputDecoration(hintText: context.l10n.searchSweets))
```

---

## 2. Key Naming Conventions in ARB Files
All keys in `app_en.arb` and `app_gu.arb` must follow lowerCamelCase with consistent descriptive prefixes:

| Category | Prefix / Pattern | Example Key | Sample Value (EN) | Sample Value (GU) |
| :--- | :--- | :--- | :--- | :--- |
| **Navigation** | `nav<Destination>` | `navHome`, `navShop`, `navOrders` | `Home` | `મુખ્ય પૃષ્ઠ` |
| **Actions & Buttons** | `action<Verb>` | `actionSave`, `actionCancel`, `actionEdit`, `actionDelete` | `Save` | `સાચવો` |
| **Section Titles** | `<feature><Section>` | `storeInformation`, `appearance` | `Store Information` | `દુકાનની માહિતી` |
| **Labels & Fields** | `<feature><Field>` | `storeName`, `customerPhone` | `Store Name` | `દુકાનનું નામ` |
| **Placeholders & Hints** | `<feature><Field>Hint` or descriptive | `searchSweets` | `Search sweets & snacks...` | `મિઠાઈ અને ફરસાણ શોધો...` |
| **Statuses** | `status<State>` | `statusPending`, `statusCompleted` | `Pending` | `બાકી` |
| **Plurals & Counts** | `itemCount`, `<noun>Count` | `itemCount` | `{count, plural, =0{No items} =1{1 item} other{{count} items}}` | `{count, plural, =0{કોઈ આઇટમ નથી} =1{1 આઇટમ} other{{count} આઇટમ્સ}}` |

---

## 3. Dynamic Text & Parameterization
- **Do not concatenate strings** with `+` or `$var` for user-facing sentences. Word order changes drastically between English and Gujarati (Subject-Verb-Object vs. Subject-Object-Verb).
- **Use ARB placeholders**:
  ```json
  "orderNumber": "Order #{id}",
  "@orderNumber": {
    "placeholders": {
      "id": { "type": "String" }
    }
  }
  ```
  ```dart
  Text(context.l10n.orderNumber(order.id))
  ```

---

## 4. Symmetry Between Locales
Whenever a new string is added:
1. Add it to `lib/l10n/app_en.arb` with metadata description.
2. Add its counterpart to `lib/l10n/app_gu.arb` with accurate Gujarati grammar.
3. Run `flutter gen-l10n` to update the generated classes.
