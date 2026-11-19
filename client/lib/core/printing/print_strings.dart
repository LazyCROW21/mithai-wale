/// Wording printed on documents.
///
/// Documents are English-only for now. To add another language, subclass this
/// and pass the instance to the document.
class PrintStrings {
  const PrintStrings();

  String get bill => 'BILL';
  String get taxInvoice => 'TAX INVOICE';
  String get billNo => 'Bill No';
  String get invoiceNo => 'Invoice No';
  String get token => 'Token';
  String get date => 'Date';
  String get billTo => 'Bill To';
  String get customer => 'Customer';
  String get phone => 'Phone';
  String get gstin => 'GSTIN';

  String get item => 'Item';
  String get delivery => 'Delivery';
  String get qty => 'Qty';
  String get rate => 'Rate';
  String get amount => 'Amount';

  String get subtotal => 'Subtotal';
  String get discount => 'Discount';
  String get total => 'Total';
  String get paid => 'Paid';
  String get balanceDue => 'Balance Due';
  String get thankYou => 'Thank you! Visit again.';
}
