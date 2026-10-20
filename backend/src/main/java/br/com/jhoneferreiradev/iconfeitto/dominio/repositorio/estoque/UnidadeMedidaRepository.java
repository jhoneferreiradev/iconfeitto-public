package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.estoque;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.unidademedida.UnidadeMedida;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseAtivavelRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UnidadeMedidaRepository extends
        JpaRepository<UnidadeMedida, Long>,
        RepositorioBaseComConfeitariaRepository<UnidadeMedida, Long>,
        RepositorioBaseAtivavelRepository<UnidadeMedida, Long> {
}
