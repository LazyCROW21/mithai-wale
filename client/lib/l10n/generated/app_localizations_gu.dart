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

  @override
  String get shoppingCartTitle => 'શોપિંગ કાર્ટ';

  @override
  String get searchToAddPlaceholder => 'ઉમેરવા માટે મિઠાઈ અને ફરસાણ શોધો...';

  @override
  String matchingSweets(int count) {
    return 'મેળ ખાતી મિઠાઈઓ અને ફરસાણ ($count)';
  }

  @override
  String noSearchResults(String query) {
    return '\"$query\" સાથે મેળ ખાતી કોઈ મિઠાઈ મળી નથી';
  }

  @override
  String itemAddedSnackbar(String name, String date) {
    return '$date માટે $name ઉમેર્યું';
  }

  @override
  String get clearCartTitle => 'કાર્ટ સાફ કરવું છે?';

  @override
  String get clearCartConfirm =>
      'શું તમે ખરેખર તમારા કાર્ટમાંથી બધી આઇટમ્સ કાઢી નાખવા માંગો છો?';

  @override
  String get changeDate => 'તારીખ બદલો';

  @override
  String get proceedToCheckout => 'ચેકઆઉટ આગળ વધો';

  @override
  String get grandTotal => 'કુલ રકમ';

  @override
  String get authLoginTitle => 'સાઇન ઇન';

  @override
  String get authLoginSubtitle => 'તમારા ફ્રેન્ચાઇઝ ખાતામાં સાઇન ઇન કરો';

  @override
  String get authFranchiseCode => 'ફ્રેન્ચાઇઝ કોડ';

  @override
  String get authUsername => 'વપરાશકર્તા નામ';

  @override
  String get authPassword => 'પાસવર્ડ';

  @override
  String get authSignIn => 'સાઇન ઇન';

  @override
  String get authSigningIn => 'સાઇન ઇન થઈ રહ્યું છે…';

  @override
  String get authFieldRequired => 'આ ફીલ્ડ આવશ્યક છે';

  @override
  String get authInvalidCredentials =>
      'ફ્રેન્ચાઇઝ કોડ, વપરાશકર્તા નામ અથવા પાસવર્ડ ખોટો છે';

  @override
  String get authNetworkError =>
      'સર્વર સુધી પહોંચી શકાતું નથી. તમારું કનેક્શન તપાસો.';

  @override
  String get authSignOutTitle => 'સાઇન આઉટ કરવું છે?';

  @override
  String get authSignOutMessage => 'તમને લૉગિન સ્ક્રીન પર પાછા લઈ જવામાં આવશે.';

  @override
  String get roleFranchiseAdmin => 'ફ્રેન્ચાઇઝ એડમિન';

  @override
  String get roleStoreOwner => 'સ્ટોર માલિક';

  @override
  String get roleEmployee => 'કર્મચારી';

  @override
  String get navManage => 'સંચાલન';

  @override
  String get navShops => 'દુકાનો';

  @override
  String get navStaff => 'સ્ટાફ';

  @override
  String get navInventory => 'ઇન્વેન્ટરી';

  @override
  String get actionRetry => 'ફરી પ્રયાસ કરો';

  @override
  String get actionEnable => 'ચાલુ કરો';

  @override
  String get actionDisable => 'બંધ કરો';

  @override
  String get statusActive => 'સક્રિય';

  @override
  String get statusDisabled => 'બંધ';

  @override
  String get errorGeneric => 'કંઈક ખોટું થયું. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get shopsEmpty => 'હજી કોઈ દુકાન નથી. તમારી પહેલી દુકાન ઉમેરો.';

  @override
  String get shopAdd => 'દુકાન ઉમેરો';

  @override
  String get shopEdit => 'દુકાન સંપાદિત કરો';

  @override
  String get shopName => 'દુકાનનું નામ';

  @override
  String get shopAddress => 'સરનામું';

  @override
  String get shopPhone => 'ફોન';

  @override
  String get staffEmpty => 'હજી કોઈ સ્ટાફ નથી. તમારી ટીમ માટે ઓળખપત્ર બનાવો.';

  @override
  String get staffAdd => 'સ્ટાફ ઉમેરો';

  @override
  String get staffEdit => 'સ્ટાફ સંપાદિત કરો';

  @override
  String get staffName => 'પૂરું નામ';

  @override
  String get staffRole => 'ભૂમિકા';

  @override
  String get staffShop => 'સોંપેલ દુકાન';

  @override
  String get staffNewPassword => 'નવો પાસવર્ડ (જાળવવા ખાલી રાખો)';

  @override
  String get staffPasswordMin => 'ઓછામાં ઓછા 8 અક્ષરો';

  @override
  String get staffNeedShop => 'પહેલા દુકાન બનાવો';

  @override
  String get inventoryEmpty => 'હજી કોઈ ઇન્વેન્ટરી આઇટમ નથી.';

  @override
  String get inventoryAdd => 'આઇટમ ઉમેરો';

  @override
  String get inventoryItemName => 'આઇટમનું નામ';

  @override
  String get inventoryUnit => 'એકમ (kg, l, pcs)';

  @override
  String get inventoryQuantity => 'જથ્થો';

  @override
  String get inventoryLowStock => 'ઓછા સ્ટોકની ચેતવણી';

  @override
  String get inventoryAdjust => 'સ્ટોક સમાયોજિત કરો';

  @override
  String get inventoryAdjustBy => 'ફેરફાર (+/-)';

  @override
  String get inventoryAllShops => 'બધી દુકાનો';

  @override
  String get inventoryShop => 'દુકાન';

  @override
  String get inventoryLow => 'ઓછું';

  @override
  String get syncTitle => 'ક્લાઉડ સિંક';

  @override
  String get syncStatusSynced => 'બધા ફેરફારો સિંક થયા';

  @override
  String get syncStatusSyncing => 'સિંક થઈ રહ્યું છે…';

  @override
  String get syncStatusOffline => 'ઑફલાઇન — ફેરફારો આ ઉપકરણ પર સાચવેલા છે';

  @override
  String syncStatusError(String message) {
    return 'સિંક સમસ્યા: $message';
  }

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ફેરફારો અપલોડ થવાના બાકી',
      one: '1 ફેરફાર અપલોડ થવાનો બાકી',
      zero: 'કોઈ બાકી ફેરફાર નથી',
    );
    return '$_temp0';
  }

  @override
  String syncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ફેરફારો સર્વરે નકાર્યા',
      one: '1 ફેરફાર સર્વરે નકાર્યો',
    );
    return '$_temp0';
  }

  @override
  String syncLastSynced(String time) {
    return 'છેલ્લે સિંક $time';
  }

  @override
  String get syncNever => 'હજી સિંક થયું નથી';

  @override
  String get syncNow => 'હમણાં સિંક કરો';

  @override
  String get syncResync => 'ક્લાઉડમાંથી ફરી સિંક કરો';

  @override
  String get syncResyncDesc =>
      'આ ઉપકરણ પરનો બધો ડેટા ક્લાઉડની તાજી નકલથી બદલો.';

  @override
  String get syncResyncConfirmTitle => 'ક્લાઉડમાંથી ફરી સિંક કરવું છે?';

  @override
  String get syncResyncConfirmBody =>
      'આ ઉપકરણ પરનો બધો ડેટા ક્લાઉડની નવીનતમ નકલથી બદલાશે. આ માટે ઇન્ટરનેટ જરૂરી છે.';

  @override
  String syncResyncPendingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'આ ઉપકરણ પરના $count ફેરફારો હજી અપલોડ થયા નથી.',
      one: 'આ ઉપકરણ પરનો 1 ફેરફાર હજી અપલોડ થયો નથી.',
    );
    return '$_temp0';
  }

  @override
  String get syncUploadThenResync => 'પહેલા અપલોડ કરો, પછી ફરી સિંક';

  @override
  String get syncDiscardAndResync => 'મારા ફેરફારો કાઢી નાખો';

  @override
  String get syncDiscardConfirm =>
      'તમારા અપલોડ ન થયેલા ફેરફારો કાયમ માટે ખોવાઈ જશે. ચાલુ રાખવું છે?';

  @override
  String syncResyncProgress(int count) {
    return 'ડાઉનલોડ થઈ રહ્યું છે… $count રેકોર્ડ';
  }

  @override
  String get syncResyncDone => 'ફરી સિંક પૂર્ણ';

  @override
  String get syncResyncFailed => 'ફરી સિંક નિષ્ફળ. તમારો હાલનો ડેટા યથાવત છે.';

  @override
  String get syncClearFailed => 'નકારાયેલા ફેરફારો દૂર કરો';

  @override
  String syncSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ફેરફારો અપલોડ થયા નથી. હમણાં સાઇન આઉટ કરવાથી તે આ ઉપકરણ પરથી કાઢી નાખવામાં આવશે.',
      one:
          '1 ફેરફાર અપલોડ થયો નથી. હમણાં સાઇન આઉટ કરવાથી તે આ ઉપકરણ પરથી કાઢી નાખવામાં આવશે.',
    );
    return '$_temp0';
  }

  @override
  String get syncSignOutAnyway => 'તો પણ સાઇન આઉટ કરો';

  @override
  String get billingShop => 'બિલિંગ દુકાન';

  @override
  String orderPlacedWithToken(String token, String amount) {
    return 'ટોકન $token · ઓર્ડર થયો (₹$amount)';
  }

  @override
  String get navDashboard => 'ડેશબોર્ડ';

  @override
  String get navMore => 'વધુ';

  @override
  String get navLedger => 'ખાતાવહી';

  @override
  String get navAudit => 'ઓડિટ લોગ';

  @override
  String get navNewOrder => 'નવો ઓર્ડર';

  @override
  String get shopFilterAll => 'બધી દુકાનો';

  @override
  String get shopFilterTooltip => 'દુકાન મુજબ ફિલ્ટર કરો';

  @override
  String get auditComingSoonTitle => 'ઓડિટ લોગ ટૂંક સમયમાં આવી રહ્યો છે';

  @override
  String get auditComingSoonBody =>
      'તમારી બધી દુકાનોમાં થયેલા દરેક ફેરફાર અહીં દેખાશે. આ ફક્ત ઓનલાઇન ઉપલબ્ધ રહેશે.';

  @override
  String get moreAccountSection => 'એકાઉન્ટ';

  @override
  String get moreManageSection => 'વ્યવસ્થાપન';

  @override
  String get orderNewTitle => 'નવો ઓર્ડર';

  @override
  String get orderShopLabel => 'દુકાન';

  @override
  String get orderShopRequired => 'દુકાન પસંદ કરો';

  @override
  String get orderSearchItems => 'વસ્તુ શોધો અને ઉમેરો';

  @override
  String get orderNoMenuItems => 'મેનુમાં કોઈ વસ્તુ ઉપલબ્ધ નથી';

  @override
  String get orderDeliveryDate => 'ડિલિવરી તારીખ';

  @override
  String get orderCustomerName => 'ગ્રાહકનું નામ';

  @override
  String get orderCustomerPhone => 'ફોન નંબર';

  @override
  String get orderWalkInCustomer => 'વૉક-ઇન ગ્રાહક';

  @override
  String get orderDiscount => 'ડિસ્કાઉન્ટ';

  @override
  String get orderDiscountNone => 'કોઈ નહીં';

  @override
  String get orderDiscountPercent => '%';

  @override
  String get orderDiscountFlat => '₹ ફ્લેટ';

  @override
  String get orderDiscountInvalid => 'યોગ્ય ડિસ્કાઉન્ટ દાખલ કરો';

  @override
  String orderItemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count વસ્તુઓ',
      one: '1 વસ્તુ',
      zero: 'કોઈ વસ્તુ ઉમેરી નથી',
    );
    return '$_temp0';
  }

  @override
  String get orderAddItemsFirst => 'ઓછામાં ઓછી એક વસ્તુ ઉમેરો';

  @override
  String get orderPlace => 'ઓર્ડર કરો';

  @override
  String get orderSetQuantity => 'જથ્થો નક્કી કરો';

  @override
  String get orderQuantity => 'જથ્થો';

  @override
  String get menuReadOnly => 'ફક્ત જોવા માટે';

  @override
  String get statusPlaced => 'ઓર્ડર થયો';

  @override
  String get statusPreparing => 'તૈયાર થઈ રહ્યું છે';

  @override
  String get statusReady => 'તૈયાર';

  @override
  String get statusDelivering => 'ડિલિવરીમાં';

  @override
  String get statusDelivered => 'ડિલિવર થયું';

  @override
  String get statusReturned => 'પરત';

  @override
  String get orderItemsInOrder => 'ઓર્ડરની વસ્તુઓ';

  @override
  String get orderNoLinesYet => 'હજુ કોઈ વસ્તુ નથી. ઉપર શોધીને વસ્તુઓ ઉમેરો.';

  @override
  String orderDeliveryOn(String date) {
    return 'ડિલિવરી · $date';
  }

  @override
  String get orderAddForAnotherDate => 'બીજી તારીખ માટે ઉમેરો';

  @override
  String get orderChangeDate => 'તારીખ બદલો';

  @override
  String get orderRemoveItem => 'દૂર કરો';

  @override
  String get orderDeliveryStatus => 'ડિલિવરી સ્થિતિ';

  @override
  String get orderOverallStatus => 'કુલ સ્થિતિ';

  @override
  String get orderStatusPerDateHint =>
      'દરેક ડિલિવરી તારીખની પોતાની સ્થિતિ છે — નીચે તારીખ પર સેટ કરો.';

  @override
  String get orderMarkAll => 'બધી તારીખો સેટ કરો';

  @override
  String orderLineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count વસ્તુઓ',
      one: '1 વસ્તુ',
    );
    return '$_temp0';
  }

  @override
  String get orderDuplicate => 'ડુપ્લિકેટ';

  @override
  String get orderMergeDuplicates => 'એક લાઇનમાં ભેગું કરો';

  @override
  String get orderDefaultDateHint =>
      'નવી વસ્તુઓ માટેની ડિફોલ્ટ તારીખ — કોઈ પણ લાઇનની તારીખ તેના તારીખ બટનથી બદલો';

  @override
  String get homeItemsToBuildTodayDesc => 'આજે બનાવવાની કુલ અલગ વસ્તુઓ';
}
