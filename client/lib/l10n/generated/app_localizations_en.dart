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

  @override
  String get syncTitle => 'Cloud sync';

  @override
  String get syncStatusSynced => 'All changes synced';

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusOffline => 'Offline — changes are saved on this device';

  @override
  String syncStatusError(String message) {
    return 'Sync problem: $message';
  }

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to upload',
      one: '1 change waiting to upload',
      zero: 'No pending changes',
    );
    return '$_temp0';
  }

  @override
  String syncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes were rejected by the server',
      one: '1 change was rejected by the server',
    );
    return '$_temp0';
  }

  @override
  String syncLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncResync => 'Re-sync from cloud';

  @override
  String get syncResyncDesc =>
      'Replace all data on this device with a fresh copy from the cloud.';

  @override
  String get syncResyncConfirmTitle => 'Re-sync from cloud?';

  @override
  String get syncResyncConfirmBody =>
      'All data on this device will be replaced with the latest copy from the cloud. This needs an internet connection.';

  @override
  String syncResyncPendingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes on this device haven\'t been uploaded yet.',
      one: '1 change on this device hasn\'t been uploaded yet.',
    );
    return '$_temp0';
  }

  @override
  String get syncUploadThenResync => 'Upload first, then re-sync';

  @override
  String get syncDiscardAndResync => 'Discard my changes';

  @override
  String get syncDiscardConfirm =>
      'Your un-uploaded changes will be lost permanently. Continue?';

  @override
  String syncResyncProgress(int count) {
    return 'Downloading… $count records';
  }

  @override
  String get syncResyncDone => 'Re-sync complete';

  @override
  String get syncResyncFailed =>
      'Re-sync failed. Your current data is unchanged.';

  @override
  String get syncClearFailed => 'Dismiss rejected changes';

  @override
  String syncSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes haven\'t been uploaded. Signing out now will delete them from this device.',
      one:
          '1 change hasn\'t been uploaded. Signing out now will delete it from this device.',
    );
    return '$_temp0';
  }

  @override
  String get syncSignOutAnyway => 'Sign out anyway';

  @override
  String get billingShop => 'Billing shop';

  @override
  String orderPlacedWithToken(String token, String amount) {
    return 'Token $token · order placed (₹$amount)';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navMore => 'More';

  @override
  String get navLedger => 'Ledger';

  @override
  String get navAudit => 'Audit log';

  @override
  String get navNewOrder => 'New order';

  @override
  String get shopFilterAll => 'All shops';

  @override
  String get shopFilterTooltip => 'Filter by shop';

  @override
  String get auditComingSoonTitle => 'Audit log is coming soon';

  @override
  String get auditComingSoonBody =>
      'Every change made across your shops will be listed here. This will be available online only.';

  @override
  String get moreAccountSection => 'Account';

  @override
  String get moreManageSection => 'Manage';

  @override
  String get orderNewTitle => 'New order';

  @override
  String get orderShopLabel => 'Shop';

  @override
  String get orderShopRequired => 'Select a shop';

  @override
  String get orderSearchItems => 'Search and add an item';

  @override
  String get orderNoMenuItems => 'No menu items available';

  @override
  String get orderDeliveryDate => 'Delivery date';

  @override
  String get orderCustomerName => 'Customer name';

  @override
  String get orderCustomerPhone => 'Phone number';

  @override
  String get orderWalkInCustomer => 'Walk-in customer';

  @override
  String get orderDiscount => 'Discount';

  @override
  String get orderDiscountNone => 'None';

  @override
  String get orderDiscountPercent => '%';

  @override
  String get orderDiscountFlat => '₹ Flat';

  @override
  String get orderDiscountInvalid => 'Enter a valid discount';

  @override
  String orderItemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items added',
    );
    return '$_temp0';
  }

  @override
  String get orderAddItemsFirst => 'Add at least one item';

  @override
  String get orderPlace => 'Place order';

  @override
  String get orderSetQuantity => 'Set quantity';

  @override
  String get orderQuantity => 'Quantity';

  @override
  String get menuReadOnly => 'View only';

  @override
  String get statusPlaced => 'Placed';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusDelivering => 'Delivering';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusReturned => 'Returned';

  @override
  String get orderItemsInOrder => 'Items in order';

  @override
  String get orderNoLinesYet => 'No items yet. Search above to add items.';

  @override
  String orderDeliveryOn(String date) {
    return 'Delivery · $date';
  }

  @override
  String get orderAddForAnotherDate => 'Add for another date';

  @override
  String get orderChangeDate => 'Change date';

  @override
  String get orderRemoveItem => 'Remove';

  @override
  String get orderDeliveryStatus => 'Delivery status';

  @override
  String get orderOverallStatus => 'Overall status';

  @override
  String get orderStatusPerDateHint =>
      'Each delivery date has its own status — set it on the date below.';

  @override
  String get orderMarkAll => 'Set all dates to';

  @override
  String orderLineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get orderDuplicate => 'Duplicate';

  @override
  String get orderMergeDuplicates => 'Merge into one row';

  @override
  String get orderDefaultDateHint =>
      'Default date for new items — change any row\'s date with its date button';

  @override
  String get homeItemsToBuildTodayDesc =>
      'Total unique items to build for today';
}
