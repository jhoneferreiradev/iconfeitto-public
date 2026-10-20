package br.com.jhoneferreiradev.iconfeitto.infra.servico.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.saidaconsumo.SaidaConsumo;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque.SaidaConsumoRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.estoque.SaidaConsumoService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class SaidaConsumoServiceImpl extends BaseServiceImpl<SaidaConsumo> implements SaidaConsumoService {

    public SaidaConsumoServiceImpl(SaidaConsumoRepository repository) {
        super(repository, "Saída consumo");
    }

}
