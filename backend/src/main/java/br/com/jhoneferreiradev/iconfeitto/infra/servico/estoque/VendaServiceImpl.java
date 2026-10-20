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

}
