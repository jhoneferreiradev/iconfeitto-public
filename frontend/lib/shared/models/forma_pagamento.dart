enum FormaPagamento {
  dinheiro('Dinheiro'),
  pix('Pix'),
  cartaoDebito('Cartão de débito'),
  cartaoCredito('Cartão de crédito');

  final String label;

  const FormaPagamento(this.label);

  static FormaPagamento fromString(String? valor) =>
      FormaPagamento.values.firstWhere(
        (forma) => forma.name == valor,
        orElse: () => FormaPagamento.dinheiro,
      );
}