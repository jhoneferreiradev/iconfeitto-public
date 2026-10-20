package br.com.jhoneferreiradev.iconfeitto.infra.servico.financeiro;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.quitacao.Quitacao;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.financeiro.QuitacaoRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.financeiro.QuitacaoService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class QuitacaoServiceImpl extends BaseServiceImpl<Quitacao> implements QuitacaoService {

    public QuitacaoServiceImpl(QuitacaoRepository repository) {
        super(repository, "Quitação");
    }

}
