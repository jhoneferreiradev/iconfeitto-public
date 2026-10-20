package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.fabricacao.Fabricacao;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.FabricacaoRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.FabricacaoService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class FabricacaoServiceImpl extends BaseServiceImpl<Fabricacao> implements FabricacaoService {

    public FabricacaoServiceImpl(FabricacaoRepository repository) {
        super(repository, "Fabricacao");
    }

}
