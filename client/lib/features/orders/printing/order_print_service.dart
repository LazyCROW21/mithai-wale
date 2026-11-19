import '../../../core/auth/auth_models.dart';
import '../../../core/database/models/order_model.dart';
import '../../../core/database/repositories/payments_repository.dart';
import '../../../core/printing/print_document.dart';
import '../../../core/printing/print_profile.dart';
import '../../../core/printing/print_profile_repository.dart';
import 'bill_data.dart';
import 'bill_document.dart';

/// Builds print jobs for orders: gathers the data (order, its payments, the
/// shop and its print setup) and picks the document. Rendering and output are
/// handled by the shared printing layer.
class OrderPrintService {
  OrderPrintService({
    required IPaymentsRepository payments,
    required IPrintProfileRepository profiles,
    required AuthSession? Function() session,
  })  : _payments = payments,
        _profiles = profiles,
        _session = session;

  final IPaymentsRepository _payments;
  final IPrintProfileRepository _profiles;
  final AuthSession? Function() _session;

  /// The customer bill of [order].
  Future<PrintJob> bill(OrderModel order) async {
    final payments = await _payments.getByOrderId(order.id);
    final shop = _shopOf(order.shopId);
    final profiles = await _profiles.load();
    return PrintJob(
      document: BillDocument(BillData.fromOrder(order, payments)),
      business: _business(shop),
      profile: profiles.resolve(shop?.id),
    );
  }

  /// A made-up bill, for trying out a print setup before saving it.
  PrintJob sampleBill(PrintProfile profile, {String? shopId}) {
    final today = DateTime.now();
    const lines = [
      ('Kaju Katli', 1.5, 'kg', 960.0),
      ('Motichoor Ladoo', 2.0, 'kg', 480.0),
      ('Samosa', 24.0, 'pc', 15.0),
    ];
    final subtotal = lines.fold<double>(0, (sum, l) => sum + l.$2 * l.$4);
    final discount = subtotal * 0.05;
    return PrintJob(
      document: BillDocument(
        BillData(
          billNumber: 'ORD-0001',
          token: 'A-12',
          orderDate: today,
          customerName: 'Sample Customer',
          customerPhone: '98765 43210',
          lines: [
            for (final l in lines)
              BillLine(
                name: l.$1,
                quantity: l.$2,
                unit: l.$3,
                unitPrice: l.$4,
                amount: l.$2 * l.$4,
                deliveryDate: today,
              ),
          ],
          subtotal: subtotal,
          discount: discount,
          discountPercent: 5,
          total: subtotal - discount,
          paid: 1000,
        ),
      ),
      business: _business(_shopOf(shopId)),
      profile: profile,
    );
  }

  /// The order's shop; store staff always print for their own shop.
  ShopRef? _shopOf(String? shopId) {
    final s = _session();
    if (s == null) return null;
    for (final shop in s.shops) {
      if (shop.id == shopId) return shop;
    }
    return s.ownShop ?? (s.shops.length == 1 ? s.shops.first : null);
  }

  BusinessInfo _business(ShopRef? shop) => BusinessInfo(
        name: shop?.name ?? _session()?.tenantName ?? '',
        address: shop?.address,
        phone: shop?.phone,
      );
}
