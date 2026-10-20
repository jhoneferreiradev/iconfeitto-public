package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.fabricacao.Fabricacao;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FabricacaoRepository extends
        JpaRepository<Fabricacao, Long>,
        RepositorioBaseComConfeitariaRepository<Fabricacao, Long> {
}
