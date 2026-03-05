class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String emoji;
  final String category;
  final String imageUrl;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
    required this.imageUrl,
  });
}

final List<ProductModel> sampleProducts = [
  ProductModel(
    id: 1,
    name: 'Air Max 270',
    description: 'Nike Running',
    price: 180.00,
    emoji: '👟',
    category: 'Zapatos',
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300&q=80',
  ),
  ProductModel(
    id: 2,
    name: 'Pro Headphones',
    description: 'Sony WH-1000XM5',
    price: 350.00,
    emoji: '🎧',
    category: 'Tech',
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&h=500&fit=crop',
  ),
  ProductModel(
    id: 3,
    name: 'Smart Watch',
    description: 'Apple Watch Series 9',
    price: 429.00,
    emoji: '⌚',
    category: 'Tech',
    imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&h=500&fit=crop',
  ),
  ProductModel(
    id: 4,
    name: 'Leather Bag',
    description: 'Premium Leather',
    price: 220.00,
    emoji: '👜',
    category: 'Moda',
    imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500&h=500&fit=crop',
  ),
  ProductModel(
    id: 5,
    name: 'Sunglasses',
    description: 'Ray-Ban Aviator',
    price: 160.00,
    emoji: '🕶️',
    category: 'Moda',
    imageUrl: 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=300&q=80',
  ),
  ProductModel(
    id: 6,
    name: 'Mechanical Keyboard',
    description: 'Keychron K2',
    price: 95.00,
    emoji: '⌨️',
    category: 'Tech',
    imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500&h=500&fit=crop',
  ),
];