class CustoOperacional {
  final String id;
  final String nome;
  final double valor;

  const CustoOperacional({
    required this.id,
    required this.nome,
    this.valor = 0.0,
  });

  //crie os métodos de conversão para Map e de Map para objeto
  Map<String, dynamic> toMap() => {'id': id, 'nome': nome, 'valor': valor};

  static CustoOperacional fromMap(Map<String, dynamic> map) => CustoOperacional(
    id: map['id'],
    nome: map['nome'],
    valor: map['valor'] ?? 0.0,
  );
}
