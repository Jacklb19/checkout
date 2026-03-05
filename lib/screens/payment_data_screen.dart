import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method_model.dart';
import '../db/database_helper.dart';
import '../main.dart';
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
  static const Color kPrimary = Color(0xFF5667F6);

  PaymentType _selectedType = PaymentType.credit;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  List<PaymentMethodModel> _savedMethods = [];
  PaymentMethodModel? _selectedSaved;
  bool _isLoading = true;
  bool _saveMethod = true;

  final _nicknameCtrl    = TextEditingController();
  final _cardNumberCtrl  = TextEditingController();
  final _monthCtrl       = TextEditingController();
  final _yearCtrl        = TextEditingController();
  final _cvvCtrl         = TextEditingController();
  final _holderCtrl      = TextEditingController();
  final _ppEmailCtrl     = TextEditingController();
  final _ppPasswordCtrl  = TextEditingController();
  final _walletPhoneCtrl = TextEditingController();
  final _walletPinCtrl   = TextEditingController();
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
    setState(() { _savedMethods = list; _isLoading = false; });
    _clearForm();
  }

  void _clearForm() {
    for (final c in [_nicknameCtrl, _cardNumberCtrl, _monthCtrl, _yearCtrl,
        _cvvCtrl, _holderCtrl, _ppEmailCtrl, _ppPasswordCtrl, _walletPhoneCtrl, _walletPinCtrl]) {
      c.clear();
    }
  }

  void _selectSaved(PaymentMethodModel? method) {
    setState(() => _selectedSaved = method);
    if (method == null) { _clearForm(); return; }
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
        _cvvCtrl, _holderCtrl, _ppEmailCtrl, _ppPasswordCtrl, _walletPhoneCtrl, _walletPinCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    PaymentMethodModel method;
    switch (_selectedType) {
      case PaymentType.credit:
        method = PaymentMethodModel(id: _selectedSaved?.id, type: PaymentType.credit,
          nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
          cardNumber: _cardNumberCtrl.text.replaceAll(' ', ''), expiryMonth: _monthCtrl.text,
          expiryYear: _yearCtrl.text, cvv: _cvvCtrl.text, cardHolder: _holderCtrl.text);
        break;
      case PaymentType.paypal:
        method = PaymentMethodModel(id: _selectedSaved?.id, type: PaymentType.paypal,
          nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
          paypalEmail: _ppEmailCtrl.text.trim(), paypalPassword: _ppPasswordCtrl.text);
        break;
      case PaymentType.wallet:
        method = PaymentMethodModel(id: _selectedSaved?.id, type: PaymentType.wallet,
          nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
          walletPhone: _walletPhoneCtrl.text.trim(), walletPin: _walletPinCtrl.text);
        break;
    }
    if (_saveMethod) {
      if (_selectedSaved != null) await DatabaseHelper.instance.updateMethod(method);
      else { final id = await DatabaseHelper.instance.insertMethod(method); method = method.copyWith(id: id); }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentConfirmScreen(totalPrice: widget.totalPrice, method: method, cart: widget.cart),
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
            _topBar(c),
            _totalBanner(c),
            const SizedBox(height: 16),
            _tabBar(c),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          children: [
                            _savedMethodsSelector(c),
                            const SizedBox(height: 16),
                            _formBody(c),
                            const SizedBox(height: 16),
                            _saveToggle(c),
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

  Widget _topBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          _backBtn(c),
          Expanded(child: Center(child: Text('Datos de pago',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _totalBanner(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total a pagar', style: TextStyle(fontSize: 13, color: c.subtext)),
          Text('\$${widget.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kPrimary)),
        ],
      ),
    );
  }

  Widget _tabBar(AppColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 50,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: c.subtext,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        padding: const EdgeInsets.all(5),
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: '💳  Crédito'), Tab(text: '🅿️  PayPal'), Tab(text: '👛  Wallet')],
      ),
    );
  }

  Widget _savedMethodsSelector(AppColors c) {
    if (_savedMethods.isEmpty) {
      return _infoChip(icon: Icons.add_circle_outline,
          text: 'No hay métodos guardados. Completa el formulario.', color: c.subtext);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Métodos guardados', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
              child: Text('${_savedMethods.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savedMethods.length + 1,
            itemBuilder: (_, i) => i == _savedMethods.length
                ? _savedChip(null, c)
                : _savedChip(_savedMethods[i], c),
          ),
        ),
        const SizedBox(height: 6),
        _selectedSaved != null
            ? _infoChip(icon: Icons.edit_outlined,
                text: 'Editando "${_selectedSaved!.displayTitle}"', color: kPrimary)
            : _infoChip(icon: Icons.add,
                text: 'Añadiendo nuevo método', color: const Color(0xFF10B981)),
      ],
    );
  }

  Widget _savedChip(PaymentMethodModel? method, AppColors c) {
    final isSelected = method == null ? _selectedSaved == null : _selectedSaved?.id == method.id;
    return GestureDetector(
      onTap: () => _selectSaved(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        width: 140,
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? kPrimary : c.divider, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: method == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: isSelected ? Colors.white : kPrimary, size: 20),
                    const SizedBox(height: 4),
                    Text('Nuevo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : c.text)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Text(method.type.icon, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      if (isSelected) Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(method.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : c.text)),
                    Text(
                      method.type == PaymentType.credit
                          ? '${method.expiryMonth}/${method.expiryYear}'
                          : method.type == PaymentType.paypal
                              ? (method.paypalEmail ?? '').split('@').first
                              : (method.walletPhone ?? ''),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: isSelected ? Colors.white.withOpacity(0.7) : c.subtext),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _formBody(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Alias (opcional)', c),
        const SizedBox(height: 8),
        _box(TextFormField(controller: _nicknameCtrl,
            decoration: _dec('ej. "Mi Visa principal"', c,
                prefix: Icon(Icons.label_outline, color: c.subtext, size: 18))), c),
        const SizedBox(height: 16),
        if (_selectedType == PaymentType.credit) _creditFields(c),
        if (_selectedType == PaymentType.paypal) _paypalFields(c),
        if (_selectedType == PaymentType.wallet) _walletFields(c),
      ],
    );
  }

  Widget _creditFields(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Número de tarjeta', c),
        const SizedBox(height: 8),
        _box(Row(children: [
          _mastercardLogo(),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(
            controller: _cardNumberCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16), _CardFmt()],
            decoration: _dec('**** **** **** ****', c),
            validator: (v) => (v ?? '').replaceAll(' ', '').length < 16 ? 'Necesita 16 dígitos' : null,
          )),
        ]), c),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Mes / Año', c),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _box(TextFormField(controller: _monthCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                      decoration: _dec('MM', c),
                      validator: (v) { if ((v ?? '').isEmpty) return 'Req.'; final m = int.tryParse(v!); return (m == null || m < 1 || m > 12) ? 'Inv.' : null; }), c)),
                  const SizedBox(width: 8),
                  Expanded(child: _box(TextFormField(controller: _yearCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                      decoration: _dec('YY', c),
                      validator: (v) => (v ?? '').length < 2 ? 'Req.' : null), c)),
                ]),
              ],
            )),
            const SizedBox(width: 14),
            SizedBox(width: 100, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('CVV', c),
                const SizedBox(height: 8),
                _box(TextFormField(controller: _cvvCtrl, obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    decoration: _dec('•••', c),
                    validator: (v) => (v ?? '').length < 3 ? 'Inv.' : null), c),
              ],
            )),
          ],
        ),
        const SizedBox(height: 14),
        _label('Titular', c),
        const SizedBox(height: 8),
        _box(TextFormField(controller: _holderCtrl, textCapitalization: TextCapitalization.words,
            decoration: _dec('Nombre completo', c),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null), c),
      ],
    );
  }

  Widget _paypalFields(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ppHeader(),
        const SizedBox(height: 16),
        _label('Correo electrónico', c),
        const SizedBox(height: 8),
        _box(TextFormField(controller: _ppEmailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: _dec('correo@ejemplo.com', c, prefix: const Icon(Icons.email_outlined, color: Color(0xFF0070BA), size: 18)),
            validator: (v) { if ((v ?? '').trim().isEmpty) return 'Requerido'; if (!v!.contains('@')) return 'Email inválido'; return null; }), c),
        const SizedBox(height: 14),
        _label('Contraseña', c),
        const SizedBox(height: 8),
        _box(TextFormField(controller: _ppPasswordCtrl, obscureText: !_ppShowPass,
            decoration: _dec('••••••••', c,
                prefix: const Icon(Icons.lock_outline, color: Color(0xFF0070BA), size: 18),
                suffix: IconButton(
                  icon: Icon(_ppShowPass ? Icons.visibility_off : Icons.visibility, size: 18, color: c.subtext),
                  onPressed: () => setState(() => _ppShowPass = !_ppShowPass))),
            validator: (v) => (v ?? '').length < 6 ? 'Mínimo 6 chars' : null), c),
      ],
    );
  }

  Widget _walletFields(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _walletHeader(),
        const SizedBox(height: 16),
        _label('Número de teléfono', c),
        const SizedBox(height: 8),
        _box(TextFormField(controller: _walletPhoneCtrl, keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: _dec('3001234567', c, prefix: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(6)),
              child: const Text('+57', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kPrimary)),
            )),
            validator: (v) => (v ?? '').length < 7 ? 'Número inválido' : null), c),
        const SizedBox(height: 14),
        _label('PIN (4 dígitos)', c),
        const SizedBox(height: 8),
        _box(TextFormField(controller: _walletPinCtrl, keyboardType: TextInputType.number, obscureText: !_walletShowPin,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            decoration: _dec('• • • •', c,
                prefix: const Icon(Icons.pin_outlined, color: Color(0xFF10B981), size: 18),
                suffix: IconButton(
                  icon: Icon(_walletShowPin ? Icons.visibility_off : Icons.visibility, size: 18, color: c.subtext),
                  onPressed: () => setState(() => _walletShowPin = !_walletShowPin))),
            validator: (v) => (v ?? '').length < 4 ? 'PIN de 4 dígitos' : null), c),
      ],
    );
  }

  Widget _ppHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0070BA), Color(0xFF003087)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Text('🅿️', style: TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PayPal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text('Pago rápido y seguro', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _walletHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Text('👛', style: TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text('Monedero digital', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _saveToggle(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Icon(Icons.save_outlined, size: 18, color: c.subtext),
        const SizedBox(width: 10),
        Expanded(child: Text('Guardar para futuros pagos',
            style: TextStyle(fontSize: 13, color: c.text, fontWeight: FontWeight.w500))),
        Switch(value: _saveMethod, onChanged: (v) => setState(() => _saveMethod = v), activeColor: kPrimary),
      ]),
    );
  }

  Widget _proceedBtn() {
    return GestureDetector(
      onTap: _proceed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5667F6), Color(0xFF7B89F9)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Center(child: Text('Continuar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
      ),
    );
  }

  Widget _label(String text, AppColors c) => Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text));

  Widget _box(Widget child, AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  InputDecoration _dec(String hint, AppColors c, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.subtext, fontSize: 14),
      border: InputBorder.none,
      errorStyle: const TextStyle(fontSize: 10, height: 0.9),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(right: 4), child: prefix) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
    );
  }

  Widget _mastercardLogo() {
    return SizedBox(width: 36, height: 22, child: Stack(children: [
      Positioned(left: 0, child: Container(width: 22, height: 22,
          decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
      Positioned(right: 0, child: Container(width: 22, height: 22,
          decoration: BoxDecoration(color: const Color(0xFFF79E1B).withOpacity(0.9), shape: BoxShape.circle))),
    ]));
  }

  Widget _infoChip({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _backBtn(AppColors c) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(Icons.arrow_back_ios_new, size: 16, color: c.text),
      ),
    );
  }
}

class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    final text = val.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(text[i]);
    }
    final s = buf.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
