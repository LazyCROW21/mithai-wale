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
