package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda.Venda;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.VendaRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.VendaService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class VendaServiceImpl extends BaseServiceImpl<Venda> implements VendaService {

    public VendaServiceImpl(VendaRepository repository) {
        super(repository, "Venda");
    }

    @Override
    public Venda salvar(Venda objeto) {
        objeto.getItens().forEach(item -> item.setMovimentacaoEstoque(objeto));
        return super.salvar(objeto);
    }

    @Override
    public Venda atualizarStatus(AtualizacaoStatusDTO atualizacaoStatus) {
        final Long id = atualizacaoStatus.getId();
        final Venda venda = getPorId(id);
        venda.setStatusVenda(atualizacaoStatus.getStatusVenda());
        venda.setDataEntrega(atualizacaoStatus.getDataEntrega());
        return repository.save(venda);
    }
}
