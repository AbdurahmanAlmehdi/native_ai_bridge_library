import 'package:native_ai_bridge/annotations/siri_annotations.dart';

@SiriTool(
  title: 'Search Products',
  description:
      'Searches the store and returns up to five in-stock products with '
      r'prices in US dollars, for example "phones under $500".',
)
class SearchProducts {
  @SiriField(
    title: 'Search',
    description: 'What the shopper is looking for and how to sort it.',
  )
  late final ProductSearch search;

  @SiriField(
    title: 'Limit',
    description: 'How many products to return, from 1 to 5.',
  )
  late final int? limit;
}

@SiriTool(
  title: 'Add to Cart',
  description: 'Adds a product to the shopping cart.',
)
class AddToCart {
  @SiriField(title: 'Product ID', description: 'The product to add.')
  late final String productId;

  @SiriField(title: 'Quantity', description: 'How many to add, 1 to 10.')
  late final int quantity;

  @SiriField(title: 'Gift Wrap', description: 'Whether to gift wrap it.')
  late final bool? giftWrap;

  @SiriField(title: 'Deliver By', description: 'The latest delivery day.')
  late final DateTime? deliverBy;

  @SiriField(title: 'Notes', description: 'Notes for the packer.')
  late final List<String> notes;

  static const maxQuantity = 10;
}

@SiriGenerableEntity(title: 'Product Search')
class ProductSearch {
  @SiriField(
    title: 'Keywords',
    description: 'Words to match in product names. Empty when none.',
  )
  late final String keywords;

  @SiriField(
    title: 'Maximum Price',
    description: 'Highest price in US dollars. 0 when not stated.',
  )
  late final double maxPrice;

  @SiriField(title: 'Sort', description: 'How to order the results.')
  late final ProductSort sort;

  @SiriField(title: 'Price Ranges', description: 'Price bands to include.')
  late final List<PriceRange> ranges;

  @SiriField(title: 'In Stock Only', description: 'Skip sold-out products.')
  late final bool inStockOnly;
}

@SiriGenerableEntity()
class PriceRange {
  @SiriField(title: 'From', description: 'Lowest price in US dollars.')
  late final double from;

  @SiriField(title: 'To', description: 'Highest price in US dollars.')
  late final double to;

  @SiriField(title: 'Since', description: 'Only products listed after.')
  late final DateTime since;
}

@SiriGenerableEntity(title: 'Sort Order')
enum ProductSort {
  @SiriField(
    title: 'Best match',
    description: 'The most relevant products first.',
  )
  relevance,
  priceLowToHigh,
  @SiriField(title: 'Newest first', description: 'Recently added first.')
  newest,
}

@SiriSkill(
  name: 'store-shopping',
  description:
      'Helps a shopper find products in the store and add them to the cart.',
  body: '''
Use the search products tool first whenever the shopper describes something
to buy. Prices are in US dollars.

## Adding to the cart

- Add a product from the search results with the quantity the shopper asked
  for, 1 when they did not say.
- Never offer to pay. Checkout happens in the app.
''',
)
abstract final class StoreShoppingSkill {}

@SiriSkill(
  name: 'order-help',
  description: 'Order help: tracking, returns and "where is my order".',
  body: 'Ask for the order number before anything else.',
)
abstract final class OrderHelpSkill {}
