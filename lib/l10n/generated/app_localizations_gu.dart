// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'મિઠાઈ વાળા';

  @override
  String get navHome => 'મુખ્ય પૃષ્ઠ';

  @override
  String get navShop => 'દુકાન';

  @override
  String get navMenu => 'મેનુ';

  @override
  String get navOrders => 'ઓર્ડર';

  @override
  String get navProfile => 'પ્રોફાઇલ';

  @override
  String get navSettings => 'સેટિંગ્સ';

  @override
  String get navCart => 'કાર્ટ';

  @override
  String get appearance => 'દેખાવ (થીમ)';

  @override
  String get themeSystem => 'સિસ્ટમ ડિફોલ્ટ';

  @override
  String get themeSystemDesc => 'ઓપરેટિંગ સિસ્ટમની થીમ મુજબ આપોઆપ ગોઠવો';

  @override
  String get themeLight => 'લાઇટ મોડ';

  @override
  String get themeLightDesc => 'કેસરી અને સ્વચ્છ લાઇટ થીમ';

  @override
  String get themeDark => 'ડાર્ક મોડ';

  @override
  String get themeDarkDesc => 'રાત્રિ વપરાશ માટે ડાર્ક થીમ';

  @override
  String get language => 'ભાષા';

  @override
  String get languageSubtitle => 'તમારી પસંદગીની ભાષા પસંદ કરો';

  @override
  String get languageEnglish => 'English (અંગ્રેજી)';

  @override
  String get languageGujarati => 'ગુજરાતી';

  @override
  String get menuCatalogManagement => 'મેનુ અને કૅટેલોગ વ્યવસ્થાપન';

  @override
  String get menuCatalogDesc =>
      'આઇટમ્સ, ઓટો આઈડી, ભાવ, એકમ (નંગ, ગ્રામ, કિગ્રા, લિટર) અને કેટેગરીનું સંચાલન કરો.';

  @override
  String get openMenu => 'મેનુ ખોલો';

  @override
  String get categories => 'કેટેગરીઓ';

  @override
  String get manageCategories => 'કેટેગરી મેનેજ કરો';

  @override
  String get storeInformation => 'દુકાનની માહિતી';

  @override
  String get storeName => 'દુકાનનું નામ';

  @override
  String get currency => 'ચલણ';

  @override
  String get currencyValue => 'INR (₹)';

  @override
  String get actionSave => 'સાચવો';

  @override
  String get actionCancel => 'રદ કરો';

  @override
  String get actionDelete => 'કાઢી નાખો';

  @override
  String get actionEdit => 'ફેરફાર કરો';

  @override
  String get actionAdd => 'ઉમેરો';

  @override
  String get actionClose => 'બંધ કરો';

  @override
  String get actionSearch => 'શોધો';

  @override
  String get actionClear => 'સાફ કરો';

  @override
  String get actionConfirm => 'પુષ્ટિ કરો';

  @override
  String get actionSignOut => 'સાઇન આઉટ';

  @override
  String get searchSweets => 'મિઠાઈ અને ફરસાણ શોધો...';

  @override
  String get allCategories => 'બધું';

  @override
  String get addToCart => 'કાર્ટમાં ઉમેરો';

  @override
  String get cartTitle => 'કાર્ટ';

  @override
  String get cartEmpty => 'તમારું કાર્ટ ખાલી છે';

  @override
  String get cartEmptyPrompt => 'દુકાનમાં નવી અને તાજી મિઠાઈ પસંદ કરો!';

  @override
  String get subtotal => 'ઉપકુલ';

  @override
  String get total => 'કુલ';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count આઇટમ્સ',
      one: '1 આઇટમ',
      zero: 'કોઈ આઇટમ નથી',
    );
    return '$_temp0';
  }

  @override
  String pricePerUnit(String price, String unit) {
    return '₹$price / $unit';
  }

  @override
  String orderNumber(String id) {
    return 'ઓર્ડર #$id';
  }

  @override
  String get statusPending => 'બાકી';

  @override
  String get statusCompleted => 'પૂર્ણ';

  @override
  String get statusCancelled => 'રદ કરેલ';
}
