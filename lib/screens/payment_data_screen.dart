import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method_model.dart';
import '../db/database_helper.dart';
import 'payment_confirm_screen.dart';

class PaymentDataScreen extends StatefulWidget {
  final double totalPrice;
  final Map<int, int> cart;

  const PaymentDataScreen({super.key, required this.totalPrice, required this.cart});

  @override
  State<PaymentDataScreen> createState() => _PaymentDataScreenState();
}

class _PaymentDataScreenState extends State<PaymentDataScreen>
    with SingleTickerProviderStateMixin {
  static const Color kBg = Color(0xFFEEF1FB);
  static const Color kPrimary = Color(0xFF5667F6);
  static const Color kText = Color(0xFF1B1E3D);
  static const Color kSubtext = Color(0xFF8A8FAE);

  PaymentType _selectedType = PaymentType.credit;
  bool _saveMethod = true;
  bool _useSaved = false;
  bool _isLoading = true;

  PaymentMethodModel? _savedMethod;

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // ── Credit fields ──
  final _cardNumberCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  // ── PayPal fields ──
  final _ppEmailCtrl = TextEditingController();
  final _ppPasswordCtrl = TextEditingController();
  bool _ppShowPass = false;

  // ── Wallet fields ──
  final _walletPhoneCtrl = TextEditingController();
  final _walletPinCtrl = TextEditingController();
  bool _walletShowPin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final types = [PaymentType.credit, PaymentType.paypal, PaymentType.wallet];
        setState(() {
          _selectedType = types[_tabController.index];
          _useSaved = false;
        });
        _loadSavedForType(types[_tabController.index]);
      }
    });
    _loadSavedForType(PaymentType.credit);
  }

  Future<void> _loadSavedForType(PaymentType type) async {
    setState(() => _isLoading = true);
    final saved = await DatabaseHelper.instance.getMethodByType(type);
    if (!mounted) return;
    setState(() {
      _savedMethod = saved;
      _useSaved = false;
      _isLoading = false;
    });
    _clearFields();
  }

  void _clearFields() {
    _cardNumberCtrl.clear();
    _monthCtrl.clear();
    _yearCtrl.clear();
    _cvvCtrl.clear();
    _holderCtrl.clear();
    _ppEmailCtrl.clear();
    _ppPasswordCtrl.clear();
    _walletPhoneCtrl.clear();
    _walletPinCtrl.clear();
  }

  void _fillFromSaved() {
    if (_savedMethod == null) return;
    switch (_savedMethod!.type) {
      case PaymentType.credit:
        _cardNumberCtrl.text = _formatCardNumber(_savedMethod!.cardNumber ?? '');
        _monthCtrl.text = _savedMethod!.expiryMonth ?? '';
        _yearCtrl.text = _savedMethod!.expiryYear ?? '';
        _cvvCtrl.text = _savedMethod!.cvv ?? '';
        _holderCtrl.text = _savedMethod!.cardHolder ?? '';
        break;
      case PaymentType.paypal:
        _ppEmailCtrl.text = _savedMethod!.paypalEmail ?? '';
        _ppPasswordCtrl.text = _savedMethod!.paypalPassword ?? '';
        break;
      case PaymentType.wallet:
        _walletPhoneCtrl.text = _savedMethod!.walletPhone ?? '';
        _walletPinCtrl.text = _savedMethod!.walletPin ?? '';
        break;
    }
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
  void dispose() {
    _tabController.dispose();
    _cardNumberCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _cvvCtrl.dispose();
    _holderCtrl.dispose();
    _ppEmailCtrl.dispose();
    _ppPasswordCtrl.dispose();
    _walletPhoneCtrl.dispose();
    _walletPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final PaymentMethodModel method;
    switch (_selectedType) {
      case PaymentType.credit:
        method = PaymentMethodModel(
          type: PaymentType.credit,
          cardNumber: _cardNumberCtrl.text.replaceAll(' ', ''),
          expiryMonth: _monthCtrl.text,
          expiryYear: _yearCtrl.text,
          cvv: _cvvCtrl.text,
          cardHolder: _holderCtrl.text,
        );
        break;
      case PaymentType.paypal:
        method = PaymentMethodModel(
          type: PaymentType.paypal,
          paypalEmail: _ppEmailCtrl.text.trim(),
          paypalPassword: _ppPasswordCtrl.text,
        );
        break;
      case PaymentType.wallet:
        method = PaymentMethodModel(
          type: PaymentType.wallet,
          walletPhone: _walletPhoneCtrl.text.trim(),
          walletPin: _walletPinCtrl.text,
        );
        break;
    }

    if (_saveMethod) {
      await DatabaseHelper.instance.upsertMethod(method);
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmScreen(
          totalPrice: widget.totalPrice,
          method: method,
          cart: widget.cart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTotalPrice(),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 4),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      if (_savedMethod != null) _buildSavedBanner(),
                      const SizedBox(height: 16),
                      _buildFormForType(),
                      const SizedBox(height: 16),
                      _buildSaveToggle(),
                      const SizedBox(height: 24),
                      _buildProceedButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                  BoxShadow(color: Colors.black.withOpacity(0.06),
                      blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Datos de pago',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTotalPrice() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total a pagar',
                  style: TextStyle(fontSize: 13, color: kSubtext)),
              Text('\$${widget.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w800, color: kPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.3),
                blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: kSubtext,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        padding: const EdgeInsets.all(5),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '💳  Crédito'),
          Tab(text: '🅿️  PayPal'),
          Tab(text: '👛  Wallet'),
        ],
      ),
    );
  }

  Widget _buildSavedBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _useSaved
            ? kPrimary.withOpacity(0.08)
            : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _useSaved ? kPrimary.withOpacity(0.3) : Colors.amber.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _useSaved ? Icons.check_circle : Icons.bookmark_outlined,
            color: _useSaved ? kPrimary : Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useSaved ? 'Usando datos guardados' : 'Tienes datos guardados',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _useSaved ? kPrimary : Colors.amber.shade800,
                  ),
                ),
                Text(
                  _savedMethod!.displayTitle,
                  style: TextStyle(fontSize: 11, color: kSubtext),
                ),
              ],
            ),
          ),
          Switch(
            value: _useSaved,
            activeColor: kPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) {
              setState(() => _useSaved = v);
              if (v) {
                _fillFromSaved();
              } else {
                _clearFields();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormForType() {
    switch (_selectedType) {
      case PaymentType.credit:
        return _buildCreditForm();
      case PaymentType.paypal:
        return _buildPayPalForm();
      case PaymentType.wallet:
        return _buildWalletForm();
    }
  }

  // ── CREDIT FORM ──────────────────────────────────────────────────────────

  Widget _buildCreditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Número de tarjeta'),
        const SizedBox(height: 8),
        _inputBox(
          child: Row(
            children: [
              _mastercardLogo(),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  decoration: _dec('**** **** **** ****'),
                  validator: (v) {
                    if (v == null || v.replaceAll(' ', '').length < 16) {
                      return 'Número inválido (16 dígitos)';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Mes / Año'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _inputBox(
                          child: TextFormField(
                            controller: _monthCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: _dec('MM'),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Req.';
                              final m = int.tryParse(v);
                              if (m == null || m < 1 || m > 12) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _inputBox(
                          child: TextFormField(
                            controller: _yearCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: _dec('YY'),
                            validator: (v) {
                              if (v == null || v.length < 2) return 'Req.';
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('CVV'),
                  const SizedBox(height: 8),
                  _inputBox(
                    child: TextFormField(
                      controller: _cvvCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: _dec('•••'),
                      validator: (v) {
                        if (v == null || v.length < 3) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label('Titular de la tarjeta'),
        const SizedBox(height: 8),
        _inputBox(
          child: TextFormField(
            controller: _holderCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Nombre completo'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              return null;
            },
          ),
        ),
      ],
    );
  }

  // ── PAYPAL FORM ──────────────────────────────────────────────────────────

  Widget _buildPayPalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPayPalHeader(),
        const SizedBox(height: 20),
        _label('Correo electrónico'),
        const SizedBox(height: 8),
        _inputBox(
          child: TextFormField(
            controller: _ppEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('correo@ejemplo.com',
                prefix: const Icon(Icons.email_outlined,
                    color: Color(0xFF0070BA), size: 20)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        _label('Contraseña de PayPal'),
        const SizedBox(height: 8),
        _inputBox(
          child: TextFormField(
            controller: _ppPasswordCtrl,
            obscureText: !_ppShowPass,
            decoration: _dec('••••••••',
                prefix: const Icon(Icons.lock_outline,
                    color: Color(0xFF0070BA), size: 20),
                suffix: IconButton(
                  icon: Icon(
                    _ppShowPass ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF8A8FAE),
                  ),
                  onPressed: () => setState(() => _ppShowPass = !_ppShowPass),
                )),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoChip(
          icon: Icons.security,
          text: 'Tus credenciales están protegidas con encriptación SSL',
          color: const Color(0xFF0070BA),
        ),
      ],
    );
  }

  Widget _buildPayPalHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0070BA), Color(0xFF003087)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🅿️', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('PayPal',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              Text('Pago rápido y seguro',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── WALLET FORM ──────────────────────────────────────────────────────────

  Widget _buildWalletForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWalletHeader(),
        const SizedBox(height: 20),
        _label('Número de teléfono vinculado'),
        const SizedBox(height: 8),
        _inputBox(
          child: TextFormField(
            controller: _walletPhoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _dec('3001234567',
                prefix: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1FB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('+57',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF5667F6))),
                )),
            validator: (v) {
              if (v == null || v.length < 7) return 'Número inválido';
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        _label('PIN de Wallet (4 dígitos)'),
        const SizedBox(height: 8),
        _inputBox(
          child: TextFormField(
            controller: _walletPinCtrl,
            keyboardType: TextInputType.number,
            obscureText: !_walletShowPin,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: _dec('• • • •',
                prefix: const Icon(Icons.pin_outlined,
                    color: Color(0xFF10B981), size: 20),
                suffix: IconButton(
                  icon: Icon(
                    _walletShowPin ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF8A8FAE),
                  ),
                  onPressed: () =>
                      setState(() => _walletShowPin = !_walletShowPin),
                )),
            validator: (v) {
              if (v == null || v.length < 4) return 'PIN de 4 dígitos';
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoChip(
          icon: Icons.account_balance_wallet_outlined,
          text: 'El saldo disponible se descontará automáticamente',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildWalletHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Center(
                child: Text('👛', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Wallet',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              Text('Monedero digital',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────────────────────

  Widget _buildInfoChip({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.save_outlined, size: 18, color: Color(0xFF8A8FAE)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Guardar para futuros pagos',
                style: TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: _saveMethod,
            onChanged: (v) => setState(() => _saveMethod = v),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF5667F6), Color(0xFF7B89F9)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: kPrimary.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: const Center(
          child: Text('Continuar para confirmar',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText));
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  InputDecoration _dec(String hint, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kSubtext, fontSize: 14),
      border: InputBorder.none,
      errorStyle: const TextStyle(fontSize: 10, height: 0.9),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      prefixIcon: prefix != null
          ? Padding(padding: const EdgeInsets.only(right: 4), child: prefix)
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
    );
  }

  Widget _mastercardLogo() {
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
                      color: Color(0xFFEB001B), shape: BoxShape.circle))),
          Positioned(
              right: 0,
              child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF79E1B).withOpacity(0.9),
                      shape: BoxShape.circle))),
        ],
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