import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../db/database_helper.dart';
import 'payment_confirm_screen.dart';

class PaymentDataScreen extends StatefulWidget {
  final double totalPrice;
  final Map<int, int> cart;

  const PaymentDataScreen({
    super.key,
    required this.totalPrice,
    required this.cart,
  });

  @override
  State<PaymentDataScreen> createState() => _PaymentDataScreenState();
}

class _PaymentDataScreenState extends State<PaymentDataScreen> {
  static const Color kBg = Color(0xFFEEF1FB);
  static const Color kPrimary = Color(0xFF5667F6);
  static const Color kText = Color(0xFF1B1E3D);
  static const Color kSubtext = Color(0xFF8A8FAE);

  String _selectedMethod = 'Credit';
  bool _saveCard = true;
  bool _isLoading = true;
  bool _hasExistingCard = false;
  CardModel? _existingCard;

  final _cardNumberController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadExistingCard();
  }

  Future<void> _loadExistingCard() async {
    final card = await DatabaseHelper.instance.getSavedCard();
    setState(() {
      _existingCard = card;
      _hasExistingCard = card != null;
      _isLoading = false;
      if (card != null) {
        // Pre-fill with masked data; real data comes from DB
        _cardNumberController.text = card.cardNumber;
        _monthController.text = card.expiryMonth;
        _yearController.text = card.expiryYear;
        _cvvController.text = card.cvv;
        _holderController.text = card.cardHolder;
        _selectedMethod = card.paymentMethod;
      }
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cvvController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;

    final card = CardModel(
      id: _existingCard?.id,
      cardNumber: _cardNumberController.text.replaceAll(' ', ''),
      expiryMonth: _monthController.text,
      expiryYear: _yearController.text,
      cvv: _cvvController.text,
      cardHolder: _holderController.text,
      paymentMethod: _selectedMethod,
    );

    if (_saveCard) {
      if (_hasExistingCard && _existingCard != null) {
        await DatabaseHelper.instance.updateCard(card);
      } else {
        await DatabaseHelper.instance.insertCard(card);
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmScreen(
          totalPrice: widget.totalPrice,
          card: card,
          cart: widget.cart,
        ),
      ),
    );
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 8),
                _buildTotalPrice(),
                const SizedBox(height: 24),
                _buildSectionLabel('Método de pago'),
                const SizedBox(height: 10),
                _buildPaymentMethods(),
                const SizedBox(height: 24),
                _buildSectionLabel('Número de tarjeta'),
                const SizedBox(height: 10),
                _buildCardNumberField(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Válida hasta'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildMonthField()),
                              const SizedBox(width: 10),
                              Expanded(child: _buildYearField()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('CVV'),
                          const SizedBox(height: 10),
                          _buildCvvField(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Titular'),
                const SizedBox(height: 10),
                _buildHolderField(),
                const SizedBox(height: 20),
                _buildSaveToggle(),
                const SizedBox(height: 28),
                _buildProceedButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Datos de pago',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTotalPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total',
          style: TextStyle(fontSize: 14, color: kSubtext),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${widget.totalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: kPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kText,
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = ['PayPal', 'Credit', 'Wallet'];
    return Row(
      children: methods.map((method) {
        final isSelected = _selectedMethod == method;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMethod = method),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    method,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kSubtext,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardNumberField() {
    return _buildInputContainer(
      child: Row(
        children: [
          _buildMastercardLogo(),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              decoration: _inputDecoration('**** **** **** ****'),
              validator: (v) {
                if (v == null || v.replaceAll(' ', '').length < 16) {
                  return 'Número inválido';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthField() {
    return _buildInputContainer(
      child: TextFormField(
        controller: _monthController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: _inputDecoration('MM'),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Requerido';
          final m = int.tryParse(v);
          if (m == null || m < 1 || m > 12) return 'Inválido';
          return null;
        },
      ),
    );
  }

  Widget _buildYearField() {
    return _buildInputContainer(
      child: TextFormField(
        controller: _yearController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: _inputDecoration('YY'),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Requerido';
          return null;
        },
      ),
    );
  }

  Widget _buildCvvField() {
    return _buildInputContainer(
      child: TextFormField(
        controller: _cvvController,
        keyboardType: TextInputType.number,
        obscureText: true,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: _inputDecoration('***'),
        validator: (v) {
          if (v == null || v.length < 3) return 'Inválido';
          return null;
        },
      ),
    );
  }

  Widget _buildHolderField() {
    return _buildInputContainer(
      child: TextFormField(
        controller: _holderController,
        textCapitalization: TextCapitalization.words,
        decoration: _inputDecoration('Nombre y apellido'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Requerido';
          return null;
        },
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kSubtext, fontSize: 14),
      border: InputBorder.none,
      errorStyle: const TextStyle(fontSize: 10),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Widget _buildMastercardLogo() {
    return SizedBox(
      width: 38,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Guardar tarjeta para futuros pagos',
              style: TextStyle(
                fontSize: 13,
                color: kText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _saveCard,
            onChanged: (v) => setState(() => _saveCard = v),
            activeColor: kPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return GestureDetector(
      onTap: _proceed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, const Color(0xFF7B89F9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Continuar para confirmar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}