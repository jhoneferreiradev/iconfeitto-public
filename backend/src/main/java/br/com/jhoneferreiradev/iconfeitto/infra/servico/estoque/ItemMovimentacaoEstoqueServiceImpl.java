package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ItemMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.ItemMovimentacaoEstoqueRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.ItemMovimentacaoEstoqueService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class ItemMovimentacaoEstoqueServiceImpl extends BaseServiceImpl<ItemMovimentacaoEstoque> implements ItemMovimentacaoEstoqueService {

    public ItemMovimentacaoEstoqueServiceImpl(ItemMovimentacaoEstoqueRepository repository) {
        super(repository, "Item movimentação de estoque");
    }

}
