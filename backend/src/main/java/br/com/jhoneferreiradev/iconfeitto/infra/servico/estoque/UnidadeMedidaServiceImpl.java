package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.UnidadeMedida;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.UnidadeMedidaRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.UnidadeMedidaService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class UnidadeMedidaServiceImpl extends BaseServiceImpl<UnidadeMedida> implements UnidadeMedidaService {

    public UnidadeMedidaServiceImpl(UnidadeMedidaRepository repository) {
        super(repository, "Unidade de medida");
    }

}
