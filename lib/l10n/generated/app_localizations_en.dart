// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Mithai Wale';

  @override
  String get navHome => 'Home';

  @override
  String get navShop => 'Shop';

  @override
  String get navMenu => 'Menu';

  @override
  String get navOrders => 'Orders';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCart => 'Cart';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeSystemDesc =>
      'Adapt automatically to operating system theme setting';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeLightDesc => 'Clean warm saffron light theme';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get themeDarkDesc => 'Sleek dark theme for night usage';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose your preferred application language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGujarati => 'ગુજરાતી (Gujarati)';

  @override
  String get menuCatalogManagement => 'Menu & Catalog Management';

  @override
  String get menuCatalogDesc =>
      'Add, edit and organize sweets menu items with auto-gen IDs, custom categories, pricing, and units.';

  @override
  String get openMenu => 'Open Menu';

  @override
  String get categories => 'Categories';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get storeInformation => 'Store Information';

  @override
  String get storeName => 'Store Name';

  @override
  String get currency => 'Currency';

  @override
  String get currencyValue => 'INR (₹)';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get searchSweets => 'Search sweets & snacks...';

  @override
  String get allCategories => 'All';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartEmptyPrompt => 'Browse the shop and add fresh sweets!';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String pricePerUnit(String price, String unit) {
    return '₹$price / $unit';
  }

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';
}
