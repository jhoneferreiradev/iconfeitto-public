import '../../models/custo_operacional.dart';
import '../../models/empresa.dart';
import 'repository_component.dart';

/// Dados da empresa e seus custos operacionais.
class EmpresaService extends RepositoryComponent {
  EmpresaService(super.context);

  Future<void> salvarEmpresa(Empresa novaEmpresa) async {
    empresa = novaEmpresa.copy(custosOperacionais: empresa.custosOperacionais);
    await db.delete('empresa');
    await db.insert('empresa', {
      'id': empresa.id,
      'nome': empresa.nome,
      'cnpjCpf': empresa.cnpjCpf,
      'telefone': empresa.telefone,
      'endereco': empresa.endereco,
      'instagram': empresa.instagram,
      'facebook': empresa.facebook,
      'logoPath': empresa.logoPath,
      'despesasGlobais': empresa.custoOperacionalPorHora,
    });
    notificar();
  }

  Future<void> adicionarCustoOperacional(CustoOperacional custo) async {
    await db.insert('custos_operacionais', {
      ...custo.toMap(),
      'empresaId': empresa.id,
    });
    empresa = empresa.copy(
      custosOperacionais: [...empresa.custosOperacionais, custo],
    );
    notificar();
  }

  Future<void> removerCustoOperacional(String custoId) async {
    await db.delete(
      'custos_operacionais',
      where: 'id = ?',
      whereArgs: [custoId],
    );
    empresa = empresa.copy(
      custosOperacionais: empresa.custosOperacionais
          .where((c) => c.id != custoId)
          .toList(),
    );
    notificar();
  }
}
