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

  String get displayTitle {
    switch (type) {
      case PaymentType.credit:
        final last4 = cardNumber != null && cardNumber!.length >= 4
            ? cardNumber!.replaceAll(' ', '').substring(
            cardNumber!.replaceAll(' ', '').length - 4)
            : '????';
        return 'Tarjeta ••••$last4';
      case PaymentType.paypal:
        return paypalEmail ?? 'PayPal';
      case PaymentType.wallet:
        return walletPhone != null ? 'Wallet · ${walletPhone}' : 'Wallet';
    }
  }

  String get displaySubtitle {
    switch (type) {
      case PaymentType.credit:
        return cardHolder ?? '';
      case PaymentType.paypal:
        return 'Cuenta PayPal';
      case PaymentType.wallet:
        return 'Monedero digital';
    }
  }
}