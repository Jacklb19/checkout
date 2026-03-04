class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String emoji;
  final String category;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
  });
}

final List<ProductModel> sampleProducts = [
  ProductModel(
    id: 1,
    name: 'Air Max 270',
    description: 'Nike Running',
    price: 180.00,
    emoji: '👟',
    category: 'Shoes',
  ),
  ProductModel(
    id: 2,
    name: 'Pro Headphones',
    description: 'Sony WH-1000XM5',
    price: 350.00,
    emoji: '🎧',
    category: 'Tech',
  ),
  ProductModel(
    id: 3,
    name: 'Smart Watch',
    description: 'Apple Watch Series 9',
    price: 429.00,
    emoji: '⌚',
    category: 'Tech',
  ),
  ProductModel(
    id: 4,
    name: 'Leather Bag',
    description: 'Premium Leather',
    price: 220.00,
    emoji: '👜',
    category: 'Fashion',
  ),
  ProductModel(
    id: 5,
    name: 'Sunglasses',
    description: 'Ray-Ban Aviator',
    price: 160.00,
    emoji: '🕶️',
    category: 'Fashion',
  ),
  ProductModel(
    id: 6,
    name: 'Mechanical Keyboard',
    description: 'Keychron K2',
    price: 95.00,
    emoji: '⌨️',
    category: 'Tech',
  ),
];