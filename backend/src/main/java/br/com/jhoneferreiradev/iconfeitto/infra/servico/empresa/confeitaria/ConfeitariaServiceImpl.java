package br.com.jhoneferreiradev.iconfeitto.infra.servico.empresa.confeitaria;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.empresa.confeitaria.ConfeitariaRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.confeitaria.ConfeitariaService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;

public class ConfeitariaServiceImpl extends BaseServiceImpl<Confeitaria> implements ConfeitariaService {

    public ConfeitariaServiceImpl(ConfeitariaRepository repository) {
        super(repository, "Confeitaria");
    }
}
