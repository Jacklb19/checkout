enum PaymentType { credit, paypal, wallet }

extension PaymentTypeExt on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.credit:
        return 'Crédito';
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.wallet:
        return 'Wallet';
    }
  }

  String get key {
    switch (this) {
      case PaymentType.credit:
        return 'Credit';
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.wallet:
        return 'Wallet';
    }
  }

  String get icon {
    switch (this) {
      case PaymentType.credit:
        return '💳';
      case PaymentType.paypal:
        return '🅿️';
      case PaymentType.wallet:
        return '👛';
    }
  }

  static PaymentType fromKey(String key) {
    switch (key) {
      case 'PayPal':
        return PaymentType.paypal;
      case 'Wallet':
        return PaymentType.wallet;
      default:
        return PaymentType.credit;
    }
  }
}

class PaymentMethodModel {
  final int? id;
  final PaymentType type;
  final String? nickname; // Nombre personalizado: "Mi Visa", "PayPal personal", etc.

  // Credit card fields
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvv;
  final String? cardHolder;

  // PayPal fields
  final String? paypalEmail;
  final String? paypalPassword;

  // Wallet fields
  final String? walletPhone;
  final String? walletPin;

  const PaymentMethodModel({
    this.id,
    required this.type,
    this.nickname,
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
    this.cardHolder,
    this.paypalEmail,
    this.paypalPassword,
    this.walletPhone,
    this.walletPin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.key,
      'nickname': nickname,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      'cardHolder': cardHolder,
      'paypalEmail': paypalEmail,
      'paypalPassword': paypalPassword,
      'walletPhone': walletPhone,
      'walletPin': walletPin,
    };
  }

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'],
      type: PaymentTypeExt.fromKey(map['type'] ?? 'Credit'),
      nickname: map['nickname'],
      cardNumber: map['cardNumber'],
      expiryMonth: map['expiryMonth'],
      expiryYear: map['expiryYear'],
      cvv: map['cvv'],
      cardHolder: map['cardHolder'],
      paypalEmail: map['paypalEmail'],
      paypalPassword: map['paypalPassword'],
      walletPhone: map['walletPhone'],
      walletPin: map['walletPin'],
    );
  }

  PaymentMethodModel copyWith({
    int? id,
    PaymentType? type,
    String? nickname,
    String? cardNumber,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    String? cardHolder,
    String? paypalEmail,
    String? paypalPassword,
    String? walletPhone,
    String? walletPin,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      nickname: nickname ?? this.nickname,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
      cardHolder: cardHolder ?? this.cardHolder,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      paypalPassword: paypalPassword ?? this.paypalPassword,
      walletPhone: walletPhone ?? this.walletPhone,
      walletPin: walletPin ?? this.walletPin,
    );
  }

  /// Nombre que se muestra en la lista de métodos guardados
  String get displayTitle {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    switch (type) {
      case PaymentType.credit:
        final raw = cardNumber?.replaceAll(' ', '') ?? '';
        final last4 = raw.length >= 4 ? raw.substring(raw.length - 4) : '????';
        return 'Tarjeta ••••$last4';
      case PaymentType.paypal:
        return paypalEmail ?? 'PayPal';
      case PaymentType.wallet:
        return walletPhone != null ? 'Wallet · $walletPhone' : 'Wallet';
    }
  }

  String get displaySubtitle {
    switch (type) {
      case PaymentType.credit:
        final raw = cardNumber?.replaceAll(' ', '') ?? '';
        final last4 = raw.length >= 4 ? raw.substring(raw.length - 4) : '????';
        return '${cardHolder ?? ''} · ••••$last4';
      case PaymentType.paypal:
        return paypalEmail ?? 'Cuenta PayPal';
      case PaymentType.wallet:
        return 'Teléfono ${walletPhone ?? ''}';
    }
  }
}