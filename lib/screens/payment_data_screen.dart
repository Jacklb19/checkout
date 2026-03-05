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
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // ── Saved methods for current tab ──
  List<PaymentMethodModel> _savedMethods = [];
  PaymentMethodModel? _selectedSaved; // null = "nuevo"
  bool _isLoading = true;
  bool _saveMethod = true;

  // ── Form controllers ──
  final _nicknameCtrl   = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _monthCtrl      = TextEditingController();
  final _yearCtrl       = TextEditingController();
  final _cvvCtrl        = TextEditingController();
  final _holderCtrl     = TextEditingController();
  final _ppEmailCtrl    = TextEditingController();
  final _ppPasswordCtrl = TextEditingController();
  final _walletPhoneCtrl = TextEditingController();
  final _walletPinCtrl  = TextEditingController();
  bool _ppShowPass = false;
  bool _walletShowPin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final types = [PaymentType.credit, PaymentType.paypal, PaymentType.wallet];
        setState(() => _selectedType = types[_tabController.index]);
        _loadSavedMethods(types[_tabController.index]);
      }
    });
    _loadSavedMethods(PaymentType.credit);
  }

  Future<void> _loadSavedMethods(PaymentType type) async {
    setState(() { _isLoading = true; _selectedSaved = null; });
    final list = await DatabaseHelper.instance.getMethodsByType(type);
    if (!mounted) return;
    setState(() {
      _savedMethods = list;
      _isLoading = false;
    });
    _clearForm();
  }

  void _clearForm() {
    _nicknameCtrl.clear();
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

  void _selectSaved(PaymentMethodModel? method) {
    setState(() => _selectedSaved = method);
    if (method == null) {
      _clearForm();
      return;
    }
    _nicknameCtrl.text = method.nickname ?? '';
    switch (method.type) {
      case PaymentType.credit:
        _cardNumberCtrl.text = _fmtCard(method.cardNumber ?? '');
        _monthCtrl.text = method.expiryMonth ?? '';
        _yearCtrl.text = method.expiryYear ?? '';
        _cvvCtrl.text = method.cvv ?? '';
        _holderCtrl.text = method.cardHolder ?? '';
        break;
      case PaymentType.paypal:
        _ppEmailCtrl.text = method.paypalEmail ?? '';
        _ppPasswordCtrl.text = method.paypalPassword ?? '';
        break;
      case PaymentType.wallet:
        _walletPhoneCtrl.text = method.walletPhone ?? '';
        _walletPinCtrl.text = method.walletPin ?? '';
        break;
    }
  }

  String _fmtCard(String v) {
    v = v.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < v.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(v[i]);
    }
    return buf.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [_nicknameCtrl, _cardNumberCtrl, _monthCtrl, _yearCtrl,
      _cvvCtrl, _holderCtrl, _ppEmailCtrl, _ppPasswordCtrl,
      _walletPhoneCtrl, _walletPinCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    PaymentMethodModel method;
    switch (_selectedType) {
      case PaymentType.credit:
        method = PaymentMethodModel(
          id: _selectedSaved?.id,
          type: PaymentType.credit,
          nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
          cardNumber: _cardNumberCtrl.text.replaceAll(' ', ''),
          expiryMonth: _monthCtrl.text,
          expiryYear: _yearCtrl.text,
          cvv: _cvvCtrl.text,
          cardHolder: _holderCtrl.text,
        );
        break;
      case PaymentType.paypal:
        method = PaymentMethodModel(
          id: _selectedSaved?.id,
          type: PaymentType.paypal,
          nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
          paypalEmail: _ppEmailCtrl.text.trim(),
          paypalPassword: _ppPasswordCtrl.text,
        );
        break;
      case PaymentType.wallet:
        method = PaymentMethodModel(
          id: _selectedSaved?.id,
          type: PaymentType.wallet,
          nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
          walletPhone: _walletPhoneCtrl.text.trim(),
          walletPin: _walletPinCtrl.text,
        );
        break;
    }

    if (_saveMethod) {
      if (_selectedSaved != null) {
        // actualizar existente
        await DatabaseHelper.instance.updateMethod(method);
      } else {
        // insertar nuevo
        final newId = await DatabaseHelper.instance.insertMethod(method);
        method = method.copyWith(id: newId);
      }
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
            _topBar(),
            _totalBanner(),
            const SizedBox(height: 16),
            _tabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      _savedMethodsSelector(),
                      const SizedBox(height: 16),
                      _formBody(),
                      const SizedBox(height: 16),
                      _saveToggle(),
                      const SizedBox(height: 24),
                      _proceedBtn(),
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

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _backBtn(() => Navigator.pop(context)),
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

  Widget _totalBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
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
                      fontSize: 32, fontWeight: FontWeight.w800, color: kPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: kSubtext,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
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

  // ── Saved methods selector ────────────────────────────────────────────────

  Widget _savedMethodsSelector() {
    if (_savedMethods.isEmpty) {
      return _infoChip(
        icon: Icons.add_circle_outline,
        text: 'No hay métodos guardados para este tipo. Completa el formulario.',
        color: kSubtext,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Métodos guardados',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: kPrimary, borderRadius: BorderRadius.circular(10)),
              child: Text('${_savedMethods.length}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Horizontal scrollable cards
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savedMethods.length + 1, // +1 for "nuevo"
            itemBuilder: (_, i) {
              if (i == _savedMethods.length) {
                // "Nuevo" card
                return _savedMethodChip(null);
              }
              return _savedMethodChip(_savedMethods[i]);
            },
          ),
        ),
        const SizedBox(height: 6),
        if (_selectedSaved != null)
          _infoChip(
            icon: Icons.edit_outlined,
            text: 'Editando "${_selectedSaved!.displayTitle}". Los cambios se guardarán sobre este método.',
            color: kPrimary,
          )
        else
          _infoChip(
            icon: Icons.add,
            text: 'Añadiendo nuevo método. Se guardará como una entrada adicional.',
            color: const Color(0xFF10B981),
          ),
      ],
    );
  }

  Widget _savedMethodChip(PaymentMethodModel? method) {
    final isSelected = method == null
        ? _selectedSaved == null
        : _selectedSaved?.id == method.id;

    return GestureDetector(
      onTap: () => _selectSaved(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        width: 140,
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimary : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: kPrimary.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: method == null
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  color: isSelected ? Colors.white : kPrimary, size: 20),
              const SizedBox(height: 4),
              Text('Nuevo',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : kText)),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(method.type.icon,
                      style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 10),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(method.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : kText)),
              Text(
                  method.type == PaymentType.credit
                      ? '${method.expiryMonth}/${method.expiryYear}'
                      : method.type == PaymentType.paypal
                      ? (method.paypalEmail ?? '').split('@').first
                      : (method.walletPhone ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withOpacity(0.7)
                          : kSubtext)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form body (delegates to each type) ───────────────────────────────────

  Widget _formBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nickname field (shared)
        _label('Alias (opcional)'),
        const SizedBox(height: 8),
        _box(
          TextFormField(
            controller: _nicknameCtrl,
            decoration: _dec('ej. "Mi Visa principal"',
                prefix: Icon(Icons.label_outline, color: kSubtext, size: 18)),
          ),
        ),
        const SizedBox(height: 16),
        // Type-specific fields
        if (_selectedType == PaymentType.credit) _creditFields(),
        if (_selectedType == PaymentType.paypal) _paypalFields(),
        if (_selectedType == PaymentType.wallet) _walletFields(),
      ],
    );
  }

  // ── Credit fields ─────────────────────────────────────────────────────────

  Widget _creditFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Número de tarjeta'),
        const SizedBox(height: 8),
        _box(Row(
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
                  _CardFmt(),
                ],
                decoration: _dec('**** **** **** ****'),
                validator: (v) => (v ?? '').replaceAll(' ', '').length < 16
                    ? 'Necesita 16 dígitos'
                    : null,
              ),
            ),
          ],
        )),
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
                        child: _box(TextFormField(
                          controller: _monthCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2)],
                          decoration: _dec('MM'),
                          validator: (v) {
                            if ((v ?? '').isEmpty) return 'Req.';
                            final m = int.tryParse(v!);
                            return (m == null || m < 1 || m > 12) ? 'Inv.' : null;
                          },
                        )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _box(TextFormField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2)],
                          decoration: _dec('YY'),
                          validator: (v) => (v ?? '').length < 2 ? 'Req.' : null,
                        )),
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
                  _box(TextFormField(
                    controller: _cvvCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4)],
                    decoration: _dec('•••'),
                    validator: (v) => (v ?? '').length < 3 ? 'Inv.' : null,
                  )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label('Titular'),
        const SizedBox(height: 8),
        _box(TextFormField(
          controller: _holderCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: _dec('Nombre completo'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
        )),
      ],
    );
  }

  // ── PayPal fields ─────────────────────────────────────────────────────────

  Widget _paypalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ppHeader(),
        const SizedBox(height: 16),
        _label('Correo electrónico'),
        const SizedBox(height: 8),
        _box(TextFormField(
          controller: _ppEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _dec('correo@ejemplo.com',
              prefix: const Icon(Icons.email_outlined,
                  color: Color(0xFF0070BA), size: 18)),
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return 'Requerido';
            if (!v!.contains('@')) return 'Email inválido';
            return null;
          },
        )),
        const SizedBox(height: 14),
        _label('Contraseña'),
        const SizedBox(height: 8),
        _box(TextFormField(
          controller: _ppPasswordCtrl,
          obscureText: !_ppShowPass,
          decoration: _dec('••••••••',
              prefix: const Icon(Icons.lock_outline,
                  color: Color(0xFF0070BA), size: 18),
              suffix: IconButton(
                icon: Icon(_ppShowPass ? Icons.visibility_off : Icons.visibility,
                    size: 18, color: kSubtext),
                onPressed: () => setState(() => _ppShowPass = !_ppShowPass),
              )),
          validator: (v) => (v ?? '').length < 6 ? 'Mínimo 6 chars' : null,
        )),
      ],
    );
  }

  Widget _ppHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0070BA), Color(0xFF003087)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Text('🅿️', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PayPal',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Pago rápido y seguro',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Wallet fields ─────────────────────────────────────────────────────────

  Widget _walletFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _walletHeader(),
        const SizedBox(height: 16),
        _label('Número de teléfono'),
        const SizedBox(height: 8),
        _box(TextFormField(
          controller: _walletPhoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10)],
          decoration: _dec('3001234567',
              prefix: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: kBg, borderRadius: BorderRadius.circular(6)),
                child: Text('+57',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: kPrimary)),
              )),
          validator: (v) => (v ?? '').length < 7 ? 'Número inválido' : null,
        )),
        const SizedBox(height: 14),
        _label('PIN (4 dígitos)'),
        const SizedBox(height: 8),
        _box(TextFormField(
          controller: _walletPinCtrl,
          keyboardType: TextInputType.number,
          obscureText: !_walletShowPin,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4)],
          decoration: _dec('• • • •',
              prefix: const Icon(Icons.pin_outlined,
                  color: Color(0xFF10B981), size: 18),
              suffix: IconButton(
                icon: Icon(_walletShowPin ? Icons.visibility_off : Icons.visibility,
                    size: 18, color: kSubtext),
                onPressed: () => setState(() => _walletShowPin = !_walletShowPin),
              )),
          validator: (v) => (v ?? '').length < 4 ? 'PIN de 4 dígitos' : null,
        )),
      ],
    );
  }

  Widget _walletHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Text('👛', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wallet',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Monedero digital',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _saveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.save_outlined, size: 18, color: kSubtext),
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

  Widget _proceedBtn() {
    return GestureDetector(
      onTap: _proceed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF5667F6), Color(0xFF7B89F9)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4),
              blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Center(
          child: Text('Continuar',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText));

  Widget _box(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
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
      width: 36,
      height: 22,
      child: Stack(children: [
        Positioned(
            left: 0,
            child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: Color(0xFFEB001B), shape: BoxShape.circle))),
        Positioned(
            right: 0,
            child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: const Color(0xFFF79E1B).withOpacity(0.9),
                    shape: BoxShape.circle))),
      ]),
    );
  }

  Widget _infoChip({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _backBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.arrow_back_ios_new, size: 16),
      ),
    );
  }
}

class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue val) {
    final text = val.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(text[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}