package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ajuste.AjusteEntrada;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.AjusteEntradaRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.AjusteEntradaService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class AjusteEntradaServiceImpl extends BaseServiceImpl<AjusteEntrada> implements AjusteEntradaService {

    public AjusteEntradaServiceImpl(AjusteEntradaRepository repository) {
        super(repository, "Ajuste entrada");
    }

}
