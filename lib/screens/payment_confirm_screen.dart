import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../models/product_model.dart';
import '../main.dart';
import 'payment_success_screen.dart';

class PaymentConfirmScreen extends StatefulWidget {
  final double totalPrice;
  final PaymentMethodModel method;
  final Map<int, int> cart;

  const PaymentConfirmScreen({super.key, required this.totalPrice, required this.method, required this.cart});

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  static const Color kPrimary = Color(0xFF5667F6);

  final _promoCtrl = TextEditingController();
  double _discount = 0;
  bool _promoApplied = false;
  bool _isProcessing = false;

  final Map<String, double> _promoCodes = {'PROMO20-08': 50.0, 'DESCUENTO10': 10.0, 'FIRST50': 50.0};

  @override
  void dispose() { _promoCtrl.dispose(); super.dispose(); }

  double get finalPrice => (widget.totalPrice - _discount).clamp(0, double.infinity);

  void _applyPromo() {
    final code = _promoCtrl.text.trim().toUpperCase();
    final discount = _promoCodes[code];
    if (discount != null) {
      setState(() { _discount = discount; _promoApplied = true; });
      _snack('¡Código aplicado! −\$${discount.toStringAsFixed(0)}', Colors.green);
    } else {
      _snack('Código inválido. Prueba: PROMO20-08', Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  Future<void> _pay() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => PaymentSuccessScreen(totalPaid: finalPrice, method: widget.method)),
      (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(c),
              const SizedBox(height: 20),
              _promoBanner(),
              const SizedBox(height: 24),
              _orderSummary(c),
              const SizedBox(height: 20),
              _paymentInfo(c),
              const SizedBox(height: 20),
              _promoSection(c),
              const SizedBox(height: 20),
              _totalCard(c),
              const SizedBox(height: 24),
              _payButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.card, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 16, color: c.text),
            ),
          ),
          Expanded(child: Center(child: Text('Confirmar pago',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _promoBanner() {
    return Container(
      width: double.infinity, height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B7BF7), Color(0xFF9B7FF5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFF6B7BF7).withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -10, bottom: -20,
              child: Text('5', style: TextStyle(fontSize: 140, fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.1)))),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(7)),
                    child: const Center(child: Text('✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('\$50 off', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  const Text('En tu primera compra', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Usa el código PROMO20-08', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sTitle('Resumen del pedido', c),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.card, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: widget.cart.entries.toList().asMap().entries.map((entry) {
              final isLast = entry.key == widget.cart.length - 1;
              final product = sampleProducts.firstWhere((p) => p.id == entry.value.key);
              final qty = entry.value.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(product.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                            Text('x$qty', style: TextStyle(fontSize: 11, color: c.subtext)),
                          ],
                        )),
                        Text('\$${(product.price * qty).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary)),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: c.divider, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _paymentInfo(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sTitle('Método de pago', c),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context),
              child: const Text('Editar', style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            _methodIcon(),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.method.displayTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                Text(widget.method.displaySubtitle, style: TextStyle(fontSize: 11, color: c.subtext)),
              ],
            )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _methodColor().withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.method.type.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _methodColor())),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _methodIcon() {
    switch (widget.method.type) {
      case PaymentType.credit:
        return SizedBox(width: 42, height: 26, child: Stack(children: [
          Positioned(left: 0, child: Container(width: 26, height: 26,
              decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
          Positioned(right: 0, child: Container(width: 26, height: 26,
              decoration: BoxDecoration(color: const Color(0xFFF79E1B).withOpacity(0.9), shape: BoxShape.circle))),
        ]));
      case PaymentType.paypal:
        return Container(width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFF0070BA), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('🅿️', style: TextStyle(fontSize: 20))));
      case PaymentType.wallet:
        return Container(width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('👛', style: TextStyle(fontSize: 20))));
    }
  }

  Color _methodColor() {
    switch (widget.method.type) {
      case PaymentType.credit: return kPrimary;
      case PaymentType.paypal: return const Color(0xFF0070BA);
      case PaymentType.wallet: return const Color(0xFF10B981);
    }
  }

  Widget _promoSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sTitle('Código promocional', c),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.card, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _promoCtrl,
              textCapitalization: TextCapitalization.characters,
              enabled: !_promoApplied,
              style: TextStyle(color: _promoApplied ? Colors.green : c.text, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'PROMO20-08',
                hintStyle: TextStyle(color: c.subtext, fontWeight: FontWeight.w600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(_promoApplied ? Icons.check_circle : Icons.local_offer_outlined,
                    color: _promoApplied ? Colors.green : c.subtext, size: 20),
              ),
            )),
            if (!_promoApplied) GestureDetector(
              onTap: _applyPromo,
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
          ]),
        ),
        if (_promoApplied) Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text('−\$${_discount.toStringAsFixed(2)} aplicado ✓',
              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _totalCard(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        _tRow('Subtotal', '\$${widget.totalPrice.toStringAsFixed(2)}', c, valueColor: c.text),
        if (_discount > 0) ...[
          const SizedBox(height: 8),
          _tRow('Descuento', '−\$${_discount.toStringAsFixed(2)}', c, valueColor: Colors.green),
        ],
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: c.divider)),
        _tRow('Total', '\$${finalPrice.toStringAsFixed(2)}', c, isBold: true, valueColor: kPrimary),
      ]),
    );
  }

  Widget _tRow(String label, String value, AppColors c, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? c.text : c.subtext)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? c.text)),
      ],
    );
  }

  Widget _payButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _pay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: _isProcessing
              ? [Colors.grey.shade500, Colors.grey.shade500]
              : [kPrimary, const Color(0xFF7B89F9)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isProcessing ? [] : [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(child: _isProcessing
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text('Pagar \$${finalPrice.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
      ),
    );
  }

  Widget _sTitle(String text, AppColors c) =>
      Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text));
}
