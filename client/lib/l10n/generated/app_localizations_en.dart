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

  @override
  String get shoppingCartTitle => 'Shopping Cart';

  @override
  String get searchToAddPlaceholder => 'Search sweets & snacks to add...';

  @override
  String matchingSweets(int count) {
    return 'Matching Sweets & Snacks ($count)';
  }

  @override
  String noSearchResults(String query) {
    return 'No sweets found matching \"$query\"';
  }

  @override
  String itemAddedSnackbar(String name, String date) {
    return 'Added $name for $date';
  }

  @override
  String get clearCartTitle => 'Clear Cart?';

  @override
  String get clearCartConfirm =>
      'Are you sure you want to remove all items from your cart?';

  @override
  String get changeDate => 'Change Date';

  @override
  String get proceedToCheckout => 'Proceed to Checkout';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle => 'Sign in to your franchise account';

  @override
  String get authFranchiseCode => 'Franchise code';

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSigningIn => 'Signing in…';

  @override
  String get authFieldRequired => 'This field is required';

  @override
  String get authInvalidCredentials =>
      'Invalid franchise code, username or password';

  @override
  String get authNetworkError =>
      'Cannot reach the server. Check your connection.';

  @override
  String get authSignOutTitle => 'Sign out?';

  @override
  String get authSignOutMessage => 'You will be returned to the login screen.';

  @override
  String get roleFranchiseAdmin => 'Franchise admin';

  @override
  String get roleStoreOwner => 'Store owner';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get navManage => 'Manage';

  @override
  String get navShops => 'Shops';

  @override
  String get navStaff => 'Staff';

  @override
  String get navInventory => 'Inventory';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionEnable => 'Enable';

  @override
  String get actionDisable => 'Disable';

  @override
  String get statusActive => 'Active';

  @override
  String get statusDisabled => 'Disabled';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get shopsEmpty => 'No shops yet. Add your first shop.';

  @override
  String get shopAdd => 'Add shop';

  @override
  String get shopEdit => 'Edit shop';

  @override
  String get shopName => 'Shop name';

  @override
  String get shopAddress => 'Address';

  @override
  String get shopPhone => 'Phone';

  @override
  String get staffEmpty => 'No staff yet. Create credentials for your team.';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffEdit => 'Edit staff';

  @override
  String get staffName => 'Full name';

  @override
  String get staffRole => 'Role';

  @override
  String get staffShop => 'Assigned shop';

  @override
  String get staffNewPassword => 'New password (leave blank to keep)';

  @override
  String get staffPasswordMin => 'At least 8 characters';

  @override
  String get staffNeedShop => 'Create a shop first';

  @override
  String get inventoryEmpty => 'No inventory items yet.';

  @override
  String get inventoryAdd => 'Add item';

  @override
  String get inventoryItemName => 'Item name';

  @override
  String get inventoryUnit => 'Unit (kg, l, pcs)';

  @override
  String get inventoryQuantity => 'Quantity';

  @override
  String get inventoryLowStock => 'Low-stock alert at';

  @override
  String get inventoryAdjust => 'Adjust stock';

  @override
  String get inventoryAdjustBy => 'Change by (+/-)';

  @override
  String get inventoryAllShops => 'All shops';

  @override
  String get inventoryShop => 'Shop';

  @override
  String get inventoryLow => 'Low';
}
