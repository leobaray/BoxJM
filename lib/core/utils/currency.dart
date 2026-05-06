class Currency {
  Currency._();

  static String format(num value) {
    final v = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $v';
  }

  static double round2(num value) => (value * 100).round() / 100;
}
