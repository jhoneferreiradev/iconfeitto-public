package br.com.jhoneferreiradev.iconfeitto.infra.servico.financeiro;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.lancamentofinanceiro.LancamentoFinanceiro;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.financeiro.LancamentoFinanceiroRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.financeiro.LancamentoFinanceiroService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class LancamentoFinanceiroServiceImpl extends BaseServiceImpl<LancamentoFinanceiro> implements LancamentoFinanceiroService {

    public LancamentoFinanceiroServiceImpl(LancamentoFinanceiroRepository repository) {
        super(repository, "Lançamento financeiro");
    }

}
