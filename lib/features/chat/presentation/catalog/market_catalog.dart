import 'package:gen_ui_demo/features/chat/presentation/catalog/price_comparison.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/shopping_list.dart';
import 'package:genui/genui.dart';

/// GenUI's basic widgets, plus our own market widgets.
final Catalog marketCatalog = BasicCatalogItems.asCatalog().copyWith(newItems: [shoppingList, priceComparison]);
