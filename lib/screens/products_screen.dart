import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../db/database_helper.dart';
import '../main.dart';
import 'payment_data_screen.dart';
import 'saved_methods_screen.dart';
import 'settings_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const Color kPrimary = Color(0xFF5667F6);

  final Map<int, int> _cart = {};
  String _selectedCategory = 'All';
  int _savedMethodsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedCount();
  }

  Future<void> _loadSavedCount() async {
    final count = await DatabaseHelper.instance.countAll();
    if (mounted) setState(() => _savedMethodsCount = count);
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
      total += sampleProducts.firstWhere((p) => p.id == id).price * qty;
    });
    return total;
  }

  void _addToCart(ProductModel product) =>
      setState(() => _cart[product.id] = (_cart[product.id] ?? 0) + 1);

  void _removeFromCart(ProductModel product) {
    setState(() {
      final current = _cart[product.id] ?? 0;
      if (current <= 1) _cart.remove(product.id);
      else _cart[product.id] = current - 1;
    });
  }

  void _clearCart() => setState(() => _cart.clear());

  void _openCart(AppColors c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        cart: _cart,
        totalPrice: totalPrice,
        colors: c,
        onAdd: _addToCart,
        onRemove: _removeFromCart,
        onClear: _clearCart,
        onCheckout: () { Navigator.pop(context); _goToCheckout(); },
      ),
    );
  }

  Future<void> _goToCheckout() async {
    if (_cart.isEmpty) {
      _snack('Tu carrito está vacío', Colors.redAccent);
      return;
    }
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentDataScreen(totalPrice: totalPrice, cart: Map.from(_cart)),
    ));
    _loadSavedCount();
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            _buildCategoryFilter(c),
            Expanded(child: _buildProductGrid(c)),
            if (totalItems > 0) _buildCartBar(c),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    final shadowColor = Colors.black.withOpacity(0.06);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tienda', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.text)),
              Text('${sampleProducts.length} productos', style: TextStyle(fontSize: 13, color: c.subtext)),
            ],
          ),
          const Spacer(),
          _iconBtn(Icons.settings_outlined, shadowColor, c, onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          const SizedBox(width: 10),
          _iconBtnBadge(Icons.account_balance_wallet_outlined, _savedMethodsCount, shadowColor, c,
              badgeColor: kPrimary, onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedMethodsScreen()));
            _loadSavedCount();
          }),
          const SizedBox(width: 10),
          _iconBtnBadge(Icons.shopping_bag_outlined, totalItems, shadowColor, c,
              filled: totalItems > 0,
              badgeColor: Colors.redAccent,
              onTap: () => _openCart(c)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color shadow, AppColors c, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: shadow, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, size: 20, color: kPrimary),
      ),
    );
  }

  Widget _iconBtnBadge(IconData icon, int count, Color shadow, AppColors c, {
    required VoidCallback onTap,
    required Color badgeColor,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: filled ? kPrimary : c.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: filled ? kPrimary.withOpacity(0.3) : shadow,
                blurRadius: 10, offset: const Offset(0, 4),
              )],
            ),
            child: Icon(icon, size: 20, color: filled ? Colors.white : kPrimary),
          ),
          if (count > 0) Positioned(
            right: 0, top: 0,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              child: Center(
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(AppColors c) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : c.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(cat, style: TextStyle(
                  color: isSelected ? Colors.white : c.subtext,
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

  Widget _buildProductGrid(AppColors c) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.68,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (_, i) => _buildProductCard(filteredProducts[i], c),
    );
  }

  Widget _buildProductCard(ProductModel product, AppColors c) {
    final qty = _cart[product.id] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(color: c.bg, child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 44)))),
                    errorBuilder: (_, __, ___) => Container(color: c.bg,
                        child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 44)))),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: c.card.withOpacity(0.92), borderRadius: BorderRadius.circular(8)),
                      child: Text(product.category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: kPrimary)),
                    ),
                  ),
                  if (qty > 0) Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                      child: Center(child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text(product.description, style: TextStyle(fontSize: 10, color: c.subtext)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('\$${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kPrimary)),
                    const Spacer(),
                    if (qty > 0) ...[
                      _qtyBtn(Icons.remove, () => _removeFromCart(product), filled: false, c: c),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('$qty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: c.text)),
                      ),
                    ],
                    _qtyBtn(Icons.add, () => _addToCart(product), filled: true, c: c),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {required bool filled, required AppColors c}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: filled ? kPrimary : c.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: filled ? Colors.white : kPrimary, size: 15),
      ),
    );
  }

  Widget _buildCartBar(AppColors c) {
    return GestureDetector(
      onTap: () => _openCart(c),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text('$totalItems items', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Text('Ver carrito →', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Cart Bottom Sheet
// ═══════════════════════════════════════════════════════════════════

class _CartSheet extends StatefulWidget {
  final Map<int, int> cart;
  final double totalPrice;
  final AppColors colors;
  final void Function(ProductModel) onAdd;
  final void Function(ProductModel) onRemove;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  const _CartSheet({
    required this.cart,
    required this.totalPrice,
    required this.colors,
    required this.onAdd,
    required this.onRemove,
    required this.onClear,
    required this.onCheckout,
  });

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  static const Color kPrimary = Color(0xFF5667F6);

  double _calcTotal(Map<int, int> cart) {
    double total = 0;
    cart.forEach((id, qty) {
      total += sampleProducts.firstWhere((p) => p.id == id).price * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final items = widget.cart.entries
        .map((e) => MapEntry(sampleProducts.firstWhere((p) => p.id == e.key), e.value))
        .toList();

    return StatefulBuilder(
      builder: (context, setModalState) {
        void doAdd(ProductModel p) { widget.onAdd(p); setModalState(() {}); }
        void doRemove(ProductModel p) { widget.onRemove(p); setModalState(() {}); }

        return Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: Row(
                  children: [
                    Text('Carrito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text)),
                    const Spacer(),
                    if (widget.cart.isNotEmpty)
                      TextButton.icon(
                        onPressed: () { widget.onClear(); Navigator.pop(context); },
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        label: const Text('Vaciar', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (widget.cart.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(children: [
                    const Text('🛒', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text('Tu carrito está vacío', style: TextStyle(color: c.subtext, fontSize: 14)),
                  ]),
                )
              else ...[
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: c.divider, indent: 56),
                    itemBuilder: (_, i) {
                      final product = items[i].key;
                      final qty = widget.cart[product.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 46, height: 46,
                                child: Image.network(product.imageUrl, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: c.bg,
                                        child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 22))))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('\$${(product.price * qty).toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 12, color: c.subtext)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _qtyBtn(Icons.remove, () => doRemove(product), filled: false, c: c),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('$qty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: c.text)),
                                ),
                                _qtyBtn(Icons.add, () => doAdd(product), filled: true, c: c),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: TextStyle(fontSize: 12, color: c.subtext)),
                          Text('\$${_calcTotal(widget.cart).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kPrimary)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onCheckout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF5667F6), Color(0xFF7B89F9)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Text('Pagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {required bool filled, required AppColors c}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: filled ? kPrimary : c.bg,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: filled ? Colors.white : kPrimary, size: 14),
      ),
    );
  }
}
