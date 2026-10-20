package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.financeiro;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.financeiro.quitacao.Quitacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface QuitacaoRepository extends JpaRepository<Quitacao, Long> {
}
