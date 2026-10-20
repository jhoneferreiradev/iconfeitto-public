package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ajuste.AjusteSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.AjusteSaidaRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.AjusteSaidaService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class AjusteSaidaServiceImpl extends BaseServiceImpl<AjusteSaida> implements AjusteSaidaService {

    public AjusteSaidaServiceImpl(AjusteSaidaRepository repository) {
        super(repository, "Ajuste saída");
    }

}
