class CardModel {
  final int? id;
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final String cardHolder;
  final String paymentMethod; 

  CardModel({
    this.id,
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.cardHolder,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      'cardHolder': cardHolder,
      'paymentMethod': paymentMethod,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      cardNumber: map['cardNumber'],
      expiryMonth: map['expiryMonth'],
      expiryYear: map['expiryYear'],
      cvv: map['cvv'],
      cardHolder: map['cardHolder'],
      paymentMethod: map['paymentMethod'],
    );
  }

  String get maskedNumber {
    if (cardNumber.length >= 4) {
      return '**${cardNumber.substring(cardNumber.length - 2)}';
    }
    return '**';
  }

  String get lastFour {
    if (cardNumber.length >= 4) {
      return cardNumber.substring(cardNumber.length - 4);
    }
    return cardNumber;
  }
}