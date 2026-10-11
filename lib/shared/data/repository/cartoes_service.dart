import '../../models/cartao_credito.dart';
import '../../models/lancamento_financeiro.dart';
import 'pessoas_financeiras_service.dart';
import 'repository_component.dart';

/// Cadastro de cartões de crédito e bandeiras.
class CartoesService extends RepositoryComponent {
  final PessoasFinanceirasService pessoasService;

  CartoesService(
    super.context, {
    required this.pessoasService,
  });

  /// Cria ou atualiza um cartão de crédito e devolve a pessoa financeira dele.
  Future<PessoaFinanceiro> salvarCartaoCredito(CartaoCredito cartao) async {
    final indice = cartoesCredito.indexWhere((c) => c.id == cartao.id);
    final linha = {
      'id': cartao.id,
      'nome': cartao.nome,
      'diaVencimento': cartao.diaVencimento,
      'diasFechamento': cartao.diasFechamento,
    };
    if (indice >= 0) {
      await db.update(
        'cartoes_credito',
        linha,
        where: 'id = ?',
        whereArgs: [cartao.id],
      );
      cartoesCredito[indice] = cartao;
    } else {
      await db.insert('cartoes_credito', linha);
      cartoesCredito.add(cartao);
    }
    final pessoa = await pessoasService.sincronizar(
      cartao.id,
      cartao.nome,
      TipoPessoaFinanceiro.cartaoCredito,
    );
    notificar();
    return pessoa;
  }

  Future<void> excluirCartaoCredito(String id) async {
    pessoasService.validarSemLancamentos(id, TipoPessoaFinanceiro.cartaoCredito, 'cartão');
    await db.delete('cartoes_credito', where: 'id = ?', whereArgs: [id]);
    cartoesCredito.removeWhere((c) => c.id == id);
    pessoasFinanceiro.removeWhere(
      (p) =>
          p.id == id && p.tipoPessoaFinanceiro == TipoPessoaFinanceiro.cartaoCredito,
    );
    notificar();
  }

  /// Cria ou atualiza uma bandeira e devolve a pessoa financeira dela.
  Future<PessoaFinanceiro> salvarBandeiraCartao(
    BandeiraCartaoCredito bandeira,
  ) async {
    final indice = bandeirasCartaoCredito.indexWhere((b) => b.id == bandeira.id);
    final linha = {
      'id': bandeira.id,
      'nome': bandeira.nome,
      'taxa': bandeira.taxa,
      'tipoTaxa': bandeira.tipoTaxa.name,
      'diasCompensacao': bandeira.diasCompensacao,
    };
    if (indice >= 0) {
      await db.update(
        'bandeiras_cartao',
        linha,
        where: 'id = ?',
        whereArgs: [bandeira.id],
      );
      bandeirasCartaoCredito[indice] = bandeira;
    } else {
      await db.insert('bandeiras_cartao', linha);
      bandeirasCartaoCredito.add(bandeira);
    }
    final pessoa = await pessoasService.sincronizar(
      bandeira.id,
      bandeira.nome,
      TipoPessoaFinanceiro.bandeiraCartaoCredito,
    );
    notificar();
    return pessoa;
  }

  Future<void> excluirBandeiraCartao(String id) async {
    pessoasService.validarSemLancamentos(
      id,
      TipoPessoaFinanceiro.bandeiraCartaoCredito,
      'bandeira',
    );
    await db.delete('bandeiras_cartao', where: 'id = ?', whereArgs: [id]);
    bandeirasCartaoCredito.removeWhere((b) => b.id == id);
    pessoasFinanceiro.removeWhere(
      (p) =>
          p.id == id &&
          p.tipoPessoaFinanceiro == TipoPessoaFinanceiro.bandeiraCartaoCredito,
    );
    notificar();
  }
}
