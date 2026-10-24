package br.com.jhoneferreiradev.iconfeitto.infra.servico.empresa.custooperacional;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.CustoOperacional;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.empresa.confeitaria.CustoOperacionalRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.custooperacinoal.CustoOperacionalService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class CustoOperacionalServiceImpl extends BaseServiceImpl<CustoOperacional> implements CustoOperacionalService {

    public CustoOperacionalServiceImpl(CustoOperacionalRepository repository) {
        super(repository, "Custo operacional");
    }
}
