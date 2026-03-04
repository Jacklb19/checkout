import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import 'products_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final double totalPaid;
  final PaymentMethodModel method;

  const PaymentSuccessScreen({
    super.key,
    required this.totalPaid,
    required this.method,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  static const Color kPrimary = Color(0xFF5667F6);
  static const Color kText = Color(0xFF1B1E3D);
  static const Color kSubtext = Color(0xFF8A8FAE);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _methodSummary {
    switch (widget.method.type) {
      case PaymentType.credit:
        final last4 = widget.method.cardNumber != null &&
            widget.method.cardNumber!.length >= 4
            ? widget.method.cardNumber!
            .replaceAll(' ', '')
            .substring(widget.method.cardNumber!.replaceAll(' ', '').length - 4)
            : '????';
        return '••••  ••••  ••••  $last4';
      case PaymentType.paypal:
        return widget.method.paypalEmail ?? 'PayPal';
      case PaymentType.wallet:
        return widget.method.walletPhone ?? 'Wallet';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5667F6), Color(0xFF7B89F9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: kPrimary.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text('¡Pago exitoso!',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: kText)),
                    const SizedBox(height: 10),
                    Text(
                        'Tu pago de \$${widget.totalPaid.toStringAsFixed(2)} fue procesado correctamente.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, color: kSubtext, height: 1.5)),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          _row('Método', widget.method.type.label),
                          const Divider(height: 20),
                          _row('Cuenta', _methodSummary),
                          const Divider(height: 20),
                          _row('Total',
                              '\$${widget.totalPaid.toStringAsFixed(2)}',
                              highlight: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductsScreen()),
                      (route) => false,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5667F6), Color(0xFF7B89F9)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: kPrimary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Center(
                    child: Text('Volver a la tienda',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: kSubtext, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: highlight ? kPrimary : kText,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                fontSize: highlight ? 16 : 13)),
      ],
    );
  }
}