package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.compra.Compra;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.CompraRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.CompraService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class CompraServiceImpl extends BaseServiceImpl<Compra> implements CompraService {

    public CompraServiceImpl(CompraRepository repository) {
        super(repository, "Compra");
    }

}
