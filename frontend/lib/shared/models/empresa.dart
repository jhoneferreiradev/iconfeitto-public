import 'custo_operacional.dart';

class Empresa {
  final String id;
  final String? nome;
  final String? cnpjCpf;
  final String? telefone;
  final String? endereco;
  final String? instagram;
  final String? facebook;
  final String? logoPath;
  final List<CustoOperacional> custosOperacionais;

  const Empresa({
    this.id = '1',
    this.nome,
    this.cnpjCpf,
    this.telefone,
    this.endereco,
    this.instagram,
    this.facebook,
    this.logoPath,
    this.custosOperacionais = const [],
  });

  double get custoOperacionalPorMinuto => custoOperacionalPorHora / 60;
  double get custoOperacionalPorHora =>
      custosOperacionais.fold(0.0, (sum, custo) => sum + custo.valor);

  Empresa copy({
    String? id,
    String? nome,
    String? cnpjCpf,
    String? telefone,
    String? endereco,
    String? instagram,
    String? facebook,
    String? logoPath,
    List<CustoOperacional>? custosOperacionais,
  }) {
    return Empresa(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cnpjCpf: cnpjCpf ?? this.cnpjCpf,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      logoPath: logoPath ?? this.logoPath,
      custosOperacionais: custosOperacionais ?? this.custosOperacionais,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'cnpjCpf': cnpjCpf,
    'telefone': telefone,
    'endereco': endereco,
    'instagram': instagram,
    'facebook': facebook,
    'logoPath': logoPath,
    'custosOperacionais': custosOperacionais.map((c) => c.toMap()).toList(),
  };

  static Empresa fromMap(Map<String, dynamic> map) => Empresa(
    id: map['id']?.toString() ?? '1',
    nome: map['nome'],
    cnpjCpf: map['cnpjCpf'],
    telefone: map['telefone'],
    endereco: map['endereco'],
    instagram: map['instagram'],
    facebook: map['facebook'],
    logoPath: map['logoPath'],
    custosOperacionais:
        (map['custosOperacionais'] as List<dynamic>?)
            ?.map((c) => CustoOperacional.fromMap(c))
            .toList() ??
        [],
  );
}
