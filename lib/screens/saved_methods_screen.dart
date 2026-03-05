import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../db/database_helper.dart';

class SavedMethodsScreen extends StatefulWidget {
  const SavedMethodsScreen({super.key});

  @override
  State<SavedMethodsScreen> createState() => _SavedMethodsScreenState();
}

class _SavedMethodsScreenState extends State<SavedMethodsScreen>
    with SingleTickerProviderStateMixin {
  static const Color kBg = Color(0xFFEEF1FB);
  static const Color kPrimary = Color(0xFF5667F6);
  static const Color kText = Color(0xFF1B1E3D);
  static const Color kSubtext = Color(0xFF8A8FAE);

  late TabController _tabController;
  Map<PaymentType, List<PaymentMethodModel>> _byType = {};
  List<Map<String, dynamic>> _rawRows = [];
  bool _isLoading = true;
  bool _showRaw = false;

  final _types = [PaymentType.credit, PaymentType.paypal, PaymentType.wallet];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 3 types + raw
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final raw = await DatabaseHelper.instance.getRawRows();
    final Map<PaymentType, List<PaymentMethodModel>> map = {};
    for (final t in _types) {
      map[t] = await DatabaseHelper.instance.getMethodsByType(t);
    }
    if (mounted) {
      setState(() {
        _byType = map;
        _rawRows = raw;
        _isLoading = false;
      });
    }
  }

  int get _total => _byType.values.fold(0, (s, l) => s + l.length);

  Future<void> _deleteOne(int id, String label) async {
    final ok = await _confirm('Eliminar "$label"',
        '¿Confirmas eliminar este método de pago?');
    if (ok) {
      await DatabaseHelper.instance.deleteById(id);
      _load();
      _snack('Eliminado', Colors.redAccent);
    }
  }

  Future<void> _deleteAll() async {
    final ok = await _confirm('Eliminar todo',
        '¿Eliminar TODOS los métodos guardados? Esta acción no se puede deshacer.');
    if (ok) {
      await DatabaseHelper.instance.deleteAllMethods();
      _load();
      _snack('Todos eliminados', Colors.redAccent);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: kSubtext))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    return result == true;
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
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            if (!_isLoading && _total > 0) _summaryBanner(),
            _tabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                controller: _tabController,
                children: [
                  ..._types.map(_buildTypeTab),
                  _buildRawTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Métodos guardados',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.refresh, size: 18, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [kPrimary.withOpacity(0.1), kPrimary.withOpacity(0.04)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.storage_outlined, color: kPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_total método(s) en la base de datos · '
                  '${_byType[PaymentType.credit]?.length ?? 0} crédito · '
                  '${_byType[PaymentType.paypal]?.length ?? 0} PayPal · '
                  '${_byType[PaymentType.wallet]?.length ?? 0} Wallet',
              style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: kPrimary, borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: kSubtext,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        padding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        tabs: [
          _tab('💳', _byType[PaymentType.credit]?.length ?? 0),
          _tab('🅿️', _byType[PaymentType.paypal]?.length ?? 0),
          _tab('👛', _byType[PaymentType.wallet]?.length ?? 0),
          _tab('🗄️', _rawRows.length),
        ],
      ),
    );
  }

  Tab _tab(String icon, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$count',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeTab(PaymentType type) {
    final methods = _byType[type] ?? [];
    if (methods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text('Sin métodos ${type.label} guardados',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
              const SizedBox(height: 6),
              Text('Realiza una compra y activa "Guardar"\npara ver los datos aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kSubtext, height: 1.5)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: methods.length + 1, // +1 for delete-all footer
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (i == methods.length) {
          return _deleteAllBtn();
        }
        return _methodCard(methods[i]);
      },
    );
  }

  Widget _methodCard(PaymentMethodModel m) {
    final color = _colorFor(m.type);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(m.type.icon,
                      style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.displayTitle,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: kText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (m.nickname != null)
                        Text('alias: ${m.nickname}',
                            style: TextStyle(fontSize: 10, color: kSubtext)),
                    ],
                  ),
                ),
                // ID chip
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('id:${m.id}',
                      style: TextStyle(
                          fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => _deleteOne(m.id!, m.displayTitle),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // ── Fields ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: _fields(m)
                  .map((f) => _fieldRow(f['label']!, f['value']!,
                  sensitive: f['s'] == '1'))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _fields(PaymentMethodModel m) {
    switch (m.type) {
      case PaymentType.credit:
        final raw = m.cardNumber?.replaceAll(' ', '') ?? '';
        final last4 = raw.length >= 4 ? raw.substring(raw.length - 4) : '????';
        return [
          {'label': 'Número', 'value': '•••• •••• •••• $last4', 's': '0'},
          {'label': 'Titular', 'value': m.cardHolder ?? '-', 's': '0'},
          {'label': 'Vence', 'value': '${m.expiryMonth}/${m.expiryYear}', 's': '0'},
          {'label': 'CVV', 'value': m.cvv ?? '•••', 's': '1'},
        ];
      case PaymentType.paypal:
        return [
          {'label': 'Email', 'value': m.paypalEmail ?? '-', 's': '0'},
          {'label': 'Password', 'value': m.paypalPassword ?? '•••', 's': '1'},
        ];
      case PaymentType.wallet:
        return [
          {'label': 'Teléfono', 'value': m.walletPhone ?? '-', 's': '0'},
          {'label': 'PIN', 'value': m.walletPin ?? '•••', 's': '1'},
        ];
    }
  }

  Widget _fieldRow(String label, String value, {bool sensitive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: kSubtext)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sensitive ? Colors.redAccent.shade200 : kText,
                    fontFamily: sensitive ? 'monospace' : null)),
          ),
        ],
      ),
    );
  }

  Widget _buildRawTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text('SELECT id, type, nickname, savedAt',
                      style: TextStyle(
                          color: Colors.greenAccent.shade400,
                          fontSize: 11,
                          fontFamily: 'monospace')),
                ],
              ),
              Text('FROM payment_methods',
                  style: TextStyle(
                      color: Colors.greenAccent.shade400,
                      fontSize: 11,
                      fontFamily: 'monospace')),
              Text('ORDER BY savedAt DESC;',
                  style: TextStyle(
                      color: Colors.greenAccent.shade400,
                      fontSize: 11,
                      fontFamily: 'monospace')),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 8),
              if (_rawRows.isEmpty)
                const Text('-- (vacío)',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontFamily: 'monospace'))
              else
                ..._rawRows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _rawField('id', '${row['id']}', Colors.yellowAccent),
                        _rawField('type', '"${row['type']}"', Colors.lightBlueAccent),
                        _rawField('nickname',
                            row['nickname'] != null ? '"${row['nickname']}"' : 'NULL',
                            row['nickname'] != null
                                ? Colors.white70
                                : Colors.white24),
                        _rawField('savedAt',
                            '"${(row['savedAt'] as String).substring(0, 19)}"',
                            Colors.white54),
                      ],
                    ),
                  ),
                )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _deleteAllBtn(),
      ],
    );
  }

  Widget _rawField(String key, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          children: [
            TextSpan(text: '$key: ',
                style: const TextStyle(color: Colors.white38)),
            TextSpan(text: value, style: TextStyle(color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _deleteAllBtn() {
    if (_total == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _deleteAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
        ),
        child: const Center(
          child: Text('🗑️  Eliminar todos los métodos guardados',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Color _colorFor(PaymentType type) {
    switch (type) {
      case PaymentType.credit:
        return kPrimary;
      case PaymentType.paypal:
        return const Color(0xFF0070BA);
      case PaymentType.wallet:
        return const Color(0xFF10B981);
    }
  }
}