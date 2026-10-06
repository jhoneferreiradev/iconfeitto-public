class BandeiraCartaoCredito {
  final String id;
  final String nome;
  final double taxa;

  const BandeiraCartaoCredito({
    required this.id,
    required this.nome,
    required this.taxa,
  });
}

class CartaoCredito {
  final String id;
  final String nome;

  const CartaoCredito({required this.id, required this.nome});
}
