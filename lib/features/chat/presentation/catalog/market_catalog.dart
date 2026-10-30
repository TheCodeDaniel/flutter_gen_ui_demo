import 'package:gen_ui_demo/features/chat/presentation/catalog/price_comparison.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/recipe_steps.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/shopping_list.dart';
import 'package:gen_ui_demo/features/chat/presentation/catalog/shopping_plan.dart';
import 'package:genui/genui.dart';

/// The widgets the AI is allowed to build with.
///
/// Every widget's schema is sent to Gemini with EVERY message, so we only keep
/// what this app needs. Fewer widgets = smaller requests = faster, cheaper replies.
final Catalog marketCatalog = BasicCatalogItems.asCatalog()
    // Basic widgets we don't need for a shopping app
    .copyWithout(
      itemsToRemove: [
        BasicCatalogItems.audioPlayer,
        BasicCatalogItems.video,
        BasicCatalogItems.image,
        BasicCatalogItems.tabs,
        BasicCatalogItems.slider,
        BasicCatalogItems.dateTimeInput,
        BasicCatalogItems.modal,
        BasicCatalogItems.list,
        BasicCatalogItems.checkBox,
      ],
      // Helper functions (validation, formatting...) our cards handle themselves
      functionsToRemove: BasicFunctions.all,
    )
    // Our own widgets, one for each step of the journey: list -> compare -> plan -> cook
    .copyWith(newItems: [shoppingList, priceComparison, shoppingPlan, recipeSteps]);
