import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  static const Color kPrimary = Color(0xFF5667F6);

  // ── Functional ──
  bool _darkMode = false;

  // ── Non-functional (UI only) ──
  int _accentIndex = 0;
  bool _pushNotifs = true;
  bool _promoNotifs = true;
  bool _orderUpdates = true;
  bool _newsletter = false;
  bool _biometrics = true;
  bool _autoLock = true;
  bool _twoFactor = false;
  bool _autoFillCard = true;
  bool _showOutOfStock = false;
  bool _showRatings = true;
  int _currencyIndex = 0;
  int _sortIndex = 0;
  double _fontSize = 1.0; // 0.8 small, 1.0 medium, 1.2 large

  late AnimationController _profileAnim;
  late Animation<double> _profileFade;

  final List<Color> _accents = [
    const Color(0xFF5667F6),
    const Color(0xFFE0454C),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
  ];

  final List<String> _currencies = ['USD \$', 'EUR €', 'COP \$', 'GBP £'];
  final List<String> _sortOptions = ['Relevancia', 'Precio ↑', 'Precio ↓', 'Más nuevo'];

  @override
  void initState() {
    super.initState();
    _darkMode = themeNotifier.value == ThemeMode.dark;
    _profileAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _profileFade =
        CurvedAnimation(parent: _profileAnim, curve: Curves.easeOut);
    _profileAnim.forward();
  }

  @override
  void dispose() {
    _profileAnim.dispose();
    super.dispose();
  }

  void _toggleDark(bool v) {
    setState(() => _darkMode = v);
    themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bool dark = _darkMode;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(c),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  FadeTransition(opacity: _profileFade, child: _profileCard(c)),
                  const SizedBox(height: 24),
                  _section('🎨  Apariencia', c, [
                    _darkTile(c, dark),
                    _divider(c),
                    _accentTile(c),
                    _divider(c),
                    _fontSizeTile(c),
                  ]),
                  const SizedBox(height: 16),
                  _section('🔔  Notificaciones', c, [
                    _switchTile('Notificaciones push', 'Alertas en tiempo real',
                        Icons.notifications_outlined, _pushNotifs,
                        (v) => setState(() => _pushNotifs = v), c),
                    _divider(c),
                    _switchTile('Promociones', 'Descuentos y ofertas especiales',
                        Icons.local_offer_outlined, _promoNotifs,
                        (v) => setState(() => _promoNotifs = v), c),
                    _divider(c),
                    _switchTile('Actualizaciones de pedido',
                        'Estado de envío en tiempo real',
                        Icons.local_shipping_outlined, _orderUpdates,
                        (v) => setState(() => _orderUpdates = v), c),
                    _divider(c),
                    _switchTile('Newsletter', 'Novedades y lanzamientos',
                        Icons.mail_outline, _newsletter,
                        (v) => setState(() => _newsletter = v), c),
                  ]),
                  const SizedBox(height: 16),
                  _section('🔒  Seguridad', c, [
                    _switchTile('Biometría', 'Huella o Face ID para pagar',
                        Icons.fingerprint, _biometrics,
                        (v) => setState(() => _biometrics = v), c),
                    _divider(c),
                    _switchTile('Bloqueo automático',
                        'Bloquear tras 5 min de inactividad',
                        Icons.lock_clock_outlined, _autoLock,
                        (v) => setState(() => _autoLock = v), c),
                    _divider(c),
                    _switchTile('Verificación en 2 pasos',
                        'Código SMS al iniciar sesión',
                        Icons.verified_user_outlined, _twoFactor,
                        (v) => setState(() => _twoFactor = v), c),
                    _divider(c),
                    _arrowTile('Cambiar contraseña', 'Última vez hace 30 días',
                        Icons.password_outlined, c,
                        badge: '!', badgeColor: Colors.orange),
                    _divider(c),
                    _arrowTile('Dispositivos activos', '2 sesiones abiertas',
                        Icons.devices_outlined, c),
                  ]),
                  const SizedBox(height: 16),
                  _section('💳  Pagos', c, [
                    _switchTile('Autocompletar tarjeta',
                        'Rellena datos guardados automáticamente',
                        Icons.auto_fix_high_outlined, _autoFillCard,
                        (v) => setState(() => _autoFillCard = v), c),
                    _divider(c),
                    _dropdownTile('Moneda', _currencies[_currencyIndex],
                        Icons.currency_exchange_outlined, c, () {
                      _showPicker(
                        context: context,
                        title: 'Moneda',
                        options: _currencies,
                        selected: _currencyIndex,
                        onSelect: (i) => setState(() => _currencyIndex = i),
                        colors: c,
                      );
                    }),
                    _divider(c),
                    _arrowTile('Método predeterminado', 'Tarjeta ••••4389',
                        Icons.credit_card_outlined, c),
                    _divider(c),
                    _arrowTile('Historial de transacciones', '14 pagos este mes',
                        Icons.receipt_long_outlined, c),
                  ]),
                  const SizedBox(height: 16),
                  _section('🛍️  Tienda', c, [
                    _switchTile('Mostrar sin stock',
                        'Ver productos agotados en la lista',
                        Icons.inventory_2_outlined, _showOutOfStock,
                        (v) => setState(() => _showOutOfStock = v), c),
                    _divider(c),
                    _switchTile('Mostrar valoraciones',
                        'Estrellas de reseñas en tarjetas',
                        Icons.star_outline, _showRatings,
                        (v) => setState(() => _showRatings = v), c),
                    _divider(c),
                    _dropdownTile('Ordenar por', _sortOptions[_sortIndex],
                        Icons.sort_outlined, c, () {
                      _showPicker(
                        context: context,
                        title: 'Ordenar por',
                        options: _sortOptions,
                        selected: _sortIndex,
                        onSelect: (i) => setState(() => _sortIndex = i),
                        colors: c,
                      );
                    }),
                    _divider(c),
                    _arrowTile('Idioma', 'Español',
                        Icons.language_outlined, c),
                  ]),
                  const SizedBox(height: 16),
                  _section('ℹ️  Acerca de', c, [
                    _arrowTile('Versión de la app', 'v3.0.0 (build 42)',
                        Icons.info_outline, c),
                    _divider(c),
                    _arrowTile('Términos y condiciones', '',
                        Icons.description_outlined, c),
                    _divider(c),
                    _arrowTile('Política de privacidad', '',
                        Icons.privacy_tip_outlined, c),
                    _divider(c),
                    _arrowTile('Contactar soporte', '',
                        Icons.headset_mic_outlined, c),
                    _divider(c),
                    _arrowTile('Calificar la app', '⭐⭐⭐⭐⭐',
                        Icons.star_border_rounded, c,
                        badge: '★', badgeColor: Colors.amber),
                  ]),
                  const SizedBox(height: 16),
                  _logoutButton(c),
                  const SizedBox(height: 8),
                  Text('Shop App © 2025 · v3.0.0',
                      style: TextStyle(fontSize: 11, color: c.subtext)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(AppColors c) {
    return SliverAppBar(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      titleSpacing: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.only(left: 16),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(Icons.arrow_back_ios_new, size: 16, color: c.text),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text('Configuración',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.settings_outlined, size: 18, color: kPrimary),
        ),
      ],
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────

  Widget _profileCard(AppColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _darkMode
              ? [const Color(0xFF252836), const Color(0xFF1A1D27)]
              : [kPrimary, const Color(0xFF7B89F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: kPrimary.withOpacity(_darkMode ? 0.2 : 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: const Center(
                    child: Text('🧑', style: TextStyle(fontSize: 30))),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carlos Rodríguez',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('carlos@email.com',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('✦ Plan Premium',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _section(String title, AppColors c, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.subtext,
                    letterSpacing: 0.3)),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(_darkMode ? 0.2 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Dark mode tile ────────────────────────────────────────────────────────

  Widget _darkTile(AppColors c, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Animated sun/moon icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF252836)
                  : const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  dark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                  key: ValueKey(dark),
                  color: dark ? const Color(0xFF7B89F9) : const Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo oscuro',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text)),
                Text(dark ? 'Activado · Descansa tus ojos' : 'Desactivado · Modo claro',
                    style: TextStyle(fontSize: 11, color: c.subtext)),
              ],
            ),
          ),
          // Custom animated toggle
          GestureDetector(
            onTap: () => _toggleDark(!dark),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: dark ? kPrimary : const Color(0xFFE0E3F0),
                borderRadius: BorderRadius.circular(15),
                boxShadow: dark
                    ? [BoxShadow(
                        color: kPrimary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3))]
                    : [],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    left: dark ? 24 : 2,
                    top: 3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Center(
                        child: Icon(
                          dark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                          size: 13,
                          color: dark
                              ? const Color(0xFF7B89F9)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Accent color tile ─────────────────────────────────────────────────────

  Widget _accentTile(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accents[_accentIndex].withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.palette_outlined,
                color: _accents[_accentIndex], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Color de acento',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_accents.length, (i) {
                    final selected = i == _accentIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _accentIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        width: selected ? 30 : 26,
                        height: selected ? 30 : 26,
                        decoration: BoxDecoration(
                          color: _accents[i],
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: c.text, width: 2.5)
                              : null,
                          boxShadow: selected
                              ? [BoxShadow(
                                  color: _accents[i].withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))]
                              : [],
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Font size tile ────────────────────────────────────────────────────────

  Widget _fontSizeTile(AppColors c) {
    final labels = ['Pequeño', 'Mediano', 'Grande'];
    final idx = _fontSize <= 0.8 ? 0 : _fontSize >= 1.2 ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.text_fields_outlined,
                color: Color(0xFF06B6D4), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Tamaño de texto',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.text)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(labels[idx],
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF06B6D4),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF06B6D4),
                    inactiveTrackColor: const Color(0xFF06B6D4).withOpacity(0.2),
                    thumbColor: const Color(0xFF06B6D4),
                    overlayColor: const Color(0xFF06B6D4).withOpacity(0.15),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 9),
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 0.8,
                    max: 1.2,
                    divisions: 2,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('A', style: TextStyle(fontSize: 11, color: c.subtext)),
                    Text('A',
                        style: TextStyle(
                            fontSize: 14,
                            color: c.subtext,
                            fontWeight: FontWeight.w600)),
                    Text('A',
                        style: TextStyle(
                            fontSize: 18,
                            color: c.subtext,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable tiles ────────────────────────────────────────────────────────

  Widget _switchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    AppColors c, {
    Color iconColor = const Color(0xFF5667F6),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.text)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: c.subtext)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _arrowTile(
    String title,
    String subtitle,
    IconData icon,
    AppColors c, {
    String? badge,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: TextStyle(fontSize: 11, color: c.subtext)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: (badgeColor ?? kPrimary).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 11,
                          color: badgeColor ?? kPrimary,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            Icon(Icons.chevron_right, size: 18, color: c.subtext),
          ],
        ),
      ),
    );
  }

  Widget _dropdownTile(
    String title,
    String value,
    IconData icon,
    AppColors c,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kPrimary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more, size: 14, color: kPrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(AppColors c) {
    return Divider(
        height: 1,
        thickness: 1,
        color: c.divider,
        indent: 70,
        endIndent: 16);
  }

  // ── Logout button ─────────────────────────────────────────────────────────

  Widget _logoutButton(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text('Cerrar sesión',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Picker bottom sheet ───────────────────────────────────────────────────

  void _showPicker({
    required BuildContext context,
    required String title,
    required List<String> options,
    required int selected,
    required ValueChanged<int> onSelect,
    required AppColors colors,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.text)),
            ),
            ...options.asMap().entries.map((e) {
              final isSelected = e.key == selected;
              return GestureDetector(
                onTap: () {
                  onSelect(e.key);
                  Navigator.pop(context);
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected ? kPrimary : colors.text)),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: kPrimary, size: 20),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
