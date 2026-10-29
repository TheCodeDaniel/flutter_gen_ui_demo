import 'package:intl/intl.dart';

/// Formats a price for display, e.g. formatPrice("₦", 25500) -> "₦25,500".
String formatPrice(String currencySymbol, num amount) {
  return NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0).format(amount);
}
