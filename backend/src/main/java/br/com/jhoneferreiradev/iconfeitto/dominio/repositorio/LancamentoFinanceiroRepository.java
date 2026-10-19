package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.lancamentofinanceiro.LancamentoFinanceiro;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LancamentoFinanceiroRepository extends
        JpaRepository<LancamentoFinanceiro, Long>,
        RepositorioBaseComConfeitariaRepository<LancamentoFinanceiro, Long> {
}
