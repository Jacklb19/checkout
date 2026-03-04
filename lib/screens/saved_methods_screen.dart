import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../db/database_helper.dart';

class SavedMethodsScreen extends StatefulWidget {
  const SavedMethodsScreen({super.key});

  @override
  State<SavedMethodsScreen> createState() => _SavedMethodsScreenState();
}

class _SavedMethodsScreenState extends State<SavedMethodsScreen> {
  static const Color kBg = Color(0xFFEEF1FB);
  static const Color kPrimary = Color(0xFF5667F6);
  static const Color kText = Color(0xFF1B1E3D);
  static const Color kSubtext = Color(0xFF8A8FAE);

  List<PaymentMethodModel> _methods = [];
  List<Map<String, dynamic>> _rawRows = [];
  bool _isLoading = true;
  bool _showRaw = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final methods = await DatabaseHelper.instance.getAllMethods();
    final raw = await DatabaseHelper.instance.getRawRows();
    if (mounted) {
      setState(() {
        _methods = methods;
        _rawRows = raw;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMethod(PaymentType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar método'),
        content: Text(
            '¿Deseas eliminar el método ${type.label} guardado?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: kSubtext))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteMethod(type);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Método eliminado'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
      }
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar todo'),
        content: const Text(
            '¿Deseas eliminar TODOS los métodos de pago guardados? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: kSubtext))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar todo',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteAllMethods();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: _methods.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          _buildInfoBanner(),
                          const SizedBox(height: 20),
                          ..._methods.map(_buildMethodCard),
                          const SizedBox(height: 20),
                          _buildRawSection(),
                          const SizedBox(height: 20),
                          _buildDeleteAllButton(),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
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
              child: Text('Métodos guardados',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _load,
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
              child: Icon(Icons.refresh, size: 18, color: kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: kPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_methods.length} método(s) guardado(s) en SQLite',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kPrimary)),
                Text(
                    'Estos datos persisten entre sesiones. Aquí puedes ver, verificar y eliminar lo que hay en la base de datos.',
                    style: TextStyle(fontSize: 11, color: kSubtext)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethodModel method) {
    final color = _colorForType(method.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(method.type.icon,
                          style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method.type.label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kText)),
                      Text(method.displayTitle,
                          style: TextStyle(fontSize: 12, color: kSubtext)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteMethod(method.type),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 18),
                  ),
                ),
              ],
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _fieldsForMethod(method)
                  .map((f) => _fieldRow(f['label']!, f['value']!, f['sensitive'] == 'true'))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _fieldsForMethod(PaymentMethodModel m) {
    switch (m.type) {
      case PaymentType.credit:
        return [
          {'label': 'Número', 'value': _maskCard(m.cardNumber ?? ''), 'sensitive': 'false'},
          {'label': 'Titular', 'value': m.cardHolder ?? '-', 'sensitive': 'false'},
          {'label': 'Vencimiento', 'value': '${m.expiryMonth}/${m.expiryYear}', 'sensitive': 'false'},
          {'label': 'CVV', 'value': m.cvv ?? '***', 'sensitive': 'true'},
        ];
      case PaymentType.paypal:
        return [
          {'label': 'Email', 'value': m.paypalEmail ?? '-', 'sensitive': 'false'},
          {'label': 'Contraseña', 'value': m.paypalPassword ?? '***', 'sensitive': 'true'},
        ];
      case PaymentType.wallet:
        return [
          {'label': 'Teléfono', 'value': m.walletPhone ?? '-', 'sensitive': 'false'},
          {'label': 'PIN', 'value': m.walletPin ?? '****', 'sensitive': 'true'},
        ];
    }
  }

  String _maskCard(String num) {
    num = num.replaceAll(' ', '');
    if (num.length >= 4) {
      return '•••• •••• •••• ${num.substring(num.length - 4)}';
    }
    return num;
  }

  Widget _fieldRow(String label, String value, bool isSensitive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: kSubtext)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSensitive ? Colors.redAccent.shade200 : kText,
                fontFamily: isSensitive ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showRaw = !_showRaw),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E3D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Ver registros RAW de SQLite',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
                Icon(
                    _showRaw ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                    size: 20),
              ],
            ),
          ),
        ),
        if (_showRaw) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E3D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// tabla: payment_methods',
                  style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                if (_rawRows.isEmpty)
                  const Text('(vacío)',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'monospace'))
                else
                  ..._rawRows.map((row) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'id=${row['id']}  type="${row['type']}"  savedAt="${(row['savedAt'] as String).substring(0, 19)}"',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeleteAllButton() {
    return GestureDetector(
      onTap: _deleteAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text('🗑️  Eliminar todos los datos guardados',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🗄️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Sin métodos guardados',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 8),
            Text(
                'Realiza una compra y activa "Guardar para futuros pagos" para ver los datos aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kSubtext, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Color _colorForType(PaymentType type) {
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
