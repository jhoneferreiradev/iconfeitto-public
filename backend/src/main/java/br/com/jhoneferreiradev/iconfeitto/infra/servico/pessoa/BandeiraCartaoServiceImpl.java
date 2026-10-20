package br.com.jhoneferreiradev.iconfeitto.infra.servico.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.bandeiracartao.BandeiraCartao;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.pessoa.BandeiraCartaoRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.BandeiraCartaoService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class BandeiraCartaoServiceImpl extends BaseServiceImpl<BandeiraCartao> implements BandeiraCartaoService {

    public BandeiraCartaoServiceImpl(BandeiraCartaoRepository repository) {
        super(repository, "Bandeira de cartão");
    }

}
