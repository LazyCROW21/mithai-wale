import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Mithai Wale'**
  String get appName;

  /// Navigation bar label for Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation bar label for Shop
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// Navigation bar label for Menu
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// Navigation bar label for Orders
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// Navigation bar label for Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Navigation bar label for Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Navigation bar label for Cart
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navCart;

  /// Header for appearance and theme settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Option for system default theme
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// Subtitle describing system default theme
  ///
  /// In en, this message translates to:
  /// **'Adapt automatically to operating system theme setting'**
  String get themeSystemDesc;

  /// Option for light theme
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLight;

  /// Subtitle describing light theme
  ///
  /// In en, this message translates to:
  /// **'Clean warm saffron light theme'**
  String get themeLightDesc;

  /// Option for dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDark;

  /// Subtitle describing dark theme
  ///
  /// In en, this message translates to:
  /// **'Sleek dark theme for night usage'**
  String get themeDarkDesc;

  /// Header for language settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Subtitle explaining language setting
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred application language'**
  String get languageSubtitle;

  /// Language label for English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language label for Gujarati
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી (Gujarati)'**
  String get languageGujarati;

  /// Title of the catalog management card
  ///
  /// In en, this message translates to:
  /// **'Menu & Catalog Management'**
  String get menuCatalogManagement;

  /// Description of the menu & catalog management feature
  ///
  /// In en, this message translates to:
  /// **'Add, edit and organize sweets menu items with auto-gen IDs, custom categories, pricing, and units.'**
  String get menuCatalogDesc;

  /// Action button to open the menu screen
  ///
  /// In en, this message translates to:
  /// **'Open Menu'**
  String get openMenu;

  /// Button to open category management
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Title and button for managing categories
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// Header for store information card
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInformation;

  /// Store name field label
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// Currency field label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Store currency
  ///
  /// In en, this message translates to:
  /// **'INR (₹)'**
  String get currencyValue;

  /// Generic save action button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic cancel action button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic delete action button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Generic edit action button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Generic add action button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// Generic close action button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Search button or field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// Clear action button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// Confirm action button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Sign out action label
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// Hint text for sweet search bar
  ///
  /// In en, this message translates to:
  /// **'Search sweets & snacks...'**
  String get searchSweets;

  /// Filter pill for all categories
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// Button to add product to cart
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Title of the cart view or sheet
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// Empty cart placeholder message
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// Prompt when cart is empty
  ///
  /// In en, this message translates to:
  /// **'Browse the shop and add fresh sweets!'**
  String get cartEmptyPrompt;

  /// Subtotal label in cart and bill
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// Total label in cart and bill
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Pluralized count of items
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// Price format per unit
  ///
  /// In en, this message translates to:
  /// **'₹{price} / {unit}'**
  String pricePerUnit(String price, String unit);

  /// Order title with order ID
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumber(String id);

  /// Order pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Order completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Order cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Header title of the shopping cart screen
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get shoppingCartTitle;

  /// Placeholder for always-visible search bar in shopping cart
  ///
  /// In en, this message translates to:
  /// **'Search sweets & snacks to add...'**
  String get searchToAddPlaceholder;

  /// Header for search results in shopping cart
  ///
  /// In en, this message translates to:
  /// **'Matching Sweets & Snacks ({count})'**
  String matchingSweets(int count);

  /// Empty state when search finds no matches
  ///
  /// In en, this message translates to:
  /// **'No sweets found matching \"{query}\"'**
  String noSearchResults(String query);

  /// Confirmation snackbar when item is added to cart
  ///
  /// In en, this message translates to:
  /// **'Added {name} for {date}'**
  String itemAddedSnackbar(String name, String date);

  /// Title for clear cart confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear Cart?'**
  String get clearCartTitle;

  /// Content for clear cart confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from your cart?'**
  String get clearCartConfirm;

  /// Button to change delivery date
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get changeDate;

  /// Button to proceed to checkout
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// Grand total label in shopping cart
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your franchise account'**
  String get authLoginSubtitle;

  /// No description provided for @authFranchiseCode.
  ///
  /// In en, this message translates to:
  /// **'Franchise code'**
  String get authFranchiseCode;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get authSigningIn;

  /// No description provided for @authFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get authFieldRequired;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid franchise code, username or password'**
  String get authInvalidCredentials;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get authNetworkError;

  /// No description provided for @authSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get authSignOutTitle;

  /// No description provided for @authSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the login screen.'**
  String get authSignOutMessage;

  /// No description provided for @roleFranchiseAdmin.
  ///
  /// In en, this message translates to:
  /// **'Franchise admin'**
  String get roleFranchiseAdmin;

  /// No description provided for @roleStoreOwner.
  ///
  /// In en, this message translates to:
  /// **'Store owner'**
  String get roleStoreOwner;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @navManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get navManage;

  /// No description provided for @navShops.
  ///
  /// In en, this message translates to:
  /// **'Shops'**
  String get navShops;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get actionEnable;

  /// No description provided for @actionDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get actionDisable;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get statusDisabled;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @shopsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shops yet. Add your first shop.'**
  String get shopsEmpty;

  /// No description provided for @shopAdd.
  ///
  /// In en, this message translates to:
  /// **'Add shop'**
  String get shopAdd;

  /// No description provided for @shopEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit shop'**
  String get shopEdit;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @shopAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shopAddress;

  /// No description provided for @shopPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get shopPhone;

  /// No description provided for @staffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No staff yet. Create credentials for your team.'**
  String get staffEmpty;

  /// No description provided for @staffAdd.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staffAdd;

  /// No description provided for @staffEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit staff'**
  String get staffEdit;

  /// No description provided for @staffName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get staffName;

  /// No description provided for @staffRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffRole;

  /// No description provided for @staffShop.
  ///
  /// In en, this message translates to:
  /// **'Assigned shop'**
  String get staffShop;

  /// No description provided for @staffNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password (leave blank to keep)'**
  String get staffNewPassword;

  /// No description provided for @staffPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get staffPasswordMin;

  /// No description provided for @staffNeedShop.
  ///
  /// In en, this message translates to:
  /// **'Create a shop first'**
  String get staffNeedShop;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No inventory items yet.'**
  String get inventoryEmpty;

  /// No description provided for @inventoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get inventoryAdd;

  /// No description provided for @inventoryItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get inventoryItemName;

  /// No description provided for @inventoryUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (kg, l, pcs)'**
  String get inventoryUnit;

  /// No description provided for @inventoryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryQuantity;

  /// No description provided for @inventoryLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alert at'**
  String get inventoryLowStock;

  /// No description provided for @inventoryAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get inventoryAdjust;

  /// No description provided for @inventoryAdjustBy.
  ///
  /// In en, this message translates to:
  /// **'Change by (+/-)'**
  String get inventoryAdjustBy;

  /// No description provided for @inventoryAllShops.
  ///
  /// In en, this message translates to:
  /// **'All shops'**
  String get inventoryAllShops;

  /// No description provided for @inventoryShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get inventoryShop;

  /// No description provided for @inventoryLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get inventoryLow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
