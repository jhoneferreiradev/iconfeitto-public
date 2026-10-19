package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria.CustoOperacional;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CustoOperacionalRepository extends
        JpaRepository<CustoOperacional, Long>,
        RepositorioBaseComConfeitariaRepository<CustoOperacional, Long> {
}
