import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../db/database_helper.dart';
import 'payment_data_screen.dart';
import 'saved_methods_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final Map<int, int> _cart = {};
  String _selectedCategory = 'All';
  int _savedMethodsCount = 0;

  static const Color kBg = Color(0xFFEEF1FB);
  static const Color kPrimary = Color(0xFF5667F6);
  static const Color kText = Color(0xFF1B1E3D);
  static const Color kSubtext = Color(0xFF8A8FAE);

  @override
  void initState() {
    super.initState();
    _loadSavedCount();
  }

  Future<void> _loadSavedCount() async {
    final methods = await DatabaseHelper.instance.getAllMethods();
    if (mounted) setState(() => _savedMethodsCount = methods.length);
  }

  List<String> get categories {
    final cats = sampleProducts.map((p) => p.category).toSet().toList();
    return ['All', ...cats];
  }

  List<ProductModel> get filteredProducts {
    if (_selectedCategory == 'All') return sampleProducts;
    return sampleProducts.where((p) => p.category == _selectedCategory).toList();
  }

  int get totalItems => _cart.values.fold(0, (a, b) => a + b);

  double get totalPrice {
    double total = 0;
    _cart.forEach((id, qty) {
      final product = sampleProducts.firstWhere((p) => p.id == id);
      total += product.price * qty;
    });
    return total;
  }

  void _addToCart(ProductModel product) {
    setState(() => _cart[product.id] = (_cart[product.id] ?? 0) + 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado'),
        duration: const Duration(milliseconds: 700),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  void _removeFromCart(ProductModel product) {
    if ((_cart[product.id] ?? 0) > 0) {
      setState(() {
        _cart[product.id] = _cart[product.id]! - 1;
        if (_cart[product.id] == 0) _cart.remove(product.id);
      });
    }
  }

  Future<void> _goToCheckout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tu carrito está vacío'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDataScreen(
          totalPrice: totalPrice,
          cart: Map.from(_cart),
        ),
      ),
    );
    _loadSavedCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryFilter(),
            Expanded(child: _buildProductGrid()),
            if (totalItems > 0) _buildCartBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tienda',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kText)),
              Text('${sampleProducts.length} productos',
                  style: TextStyle(fontSize: 13, color: kSubtext)),
            ],
          ),
          const Spacer(),
          // ── Saved methods button ──
          GestureDetector(
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SavedMethodsScreen()));
              _loadSavedCount();
            },
            child: Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06),
                          blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      size: 20, color: Color(0xFF5667F6)),
                ),
                if (_savedMethodsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                          color: Color(0xFF5667F6), shape: BoxShape.circle),
                      child: Center(
                        child: Text('$_savedMethodsCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Cart icon ──
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06),
                        blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(Icons.shopping_bag_outlined, color: kPrimary, size: 22),
              ),
              if (totalItems > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$totalItems',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: kPrimary.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kSubtext,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (_, i) => _buildProductCard(filteredProducts[i]),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final qty = _cart[product.id] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 14, offset: const Offset(0, 6))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: kBg, borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 52))),
              ),
            ),
            const SizedBox(height: 10),
            Text(product.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(product.description,
                style: TextStyle(fontSize: 11, color: kSubtext)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('\$${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary)),
                const Spacer(),
                if (qty > 0) ...[
                  GestureDetector(
                    onTap: () => _removeFromCart(product),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: kBg, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.remove, color: kPrimary, size: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('$qty',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: kText)),
                  ),
                ],
                GestureDetector(
                  onTap: () => _addToCart(product),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: qty > 0 ? kPrimary : kBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add,
                        color: qty > 0 ? Colors.white : kPrimary, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kPrimary.withOpacity(0.4),
              blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Text('$totalItems items',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          GestureDetector(
            onTap: _goToCheckout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Text('Checkout →',
                  style: TextStyle(
                      color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}